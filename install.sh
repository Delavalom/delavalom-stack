#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Delavalom Stack Installer v3.0.0
# Installs the vendored skill set + shell configuration
# ============================================================

VERSION="3.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
STACK_CLAUDE="${SCRIPT_DIR}/.claude"
STACK_SKILLS="${STACK_CLAUDE}/skills"
USER_SKILLS="${CLAUDE_HOME}/skills"
BACKUP_ROOT="${CLAUDE_HOME}/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

INSTALLED_SKILLS=0

# ============================================================
# Helpers
# ============================================================

print_banner() {
    echo -e "${PURPLE}"
    echo "  +===================================================+"
    echo "  |         DELAVALOM STACK INSTALLER                  |"
    echo "  |         v${VERSION} -- Skills + Shell                   |"
    echo "  +===================================================+"
    echo -e "${NC}"
}

log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERR]${NC}  $1"; }
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_dry()  { echo -e "${DIM}[DRY]${NC}  $1"; }

die() { log_err "$1"; exit 1; }

run_mkdir() {
    if $DRY_RUN; then log_dry "mkdir -p $1"; else mkdir -p "$1"; fi
}

run_cp() {
    if $DRY_RUN; then log_dry "cp $1 -> $2"; else cp "$1" "$2"; fi
}

run_rm_r() {
    if $DRY_RUN; then log_dry "rm -rf $1"; else rm -rf "$1"; fi
}

# Copy a directory tree, excluding VCS and OS cruft.
copy_tree() {
    local src="$1" dst="$2"
    if $DRY_RUN; then
        log_dry "copy tree $src -> $dst"
        return
    fi
    rm -rf "$dst"
    mkdir -p "$dst"
    if command -v rsync &>/dev/null; then
        rsync -a --exclude '.git' --exclude '.DS_Store' "${src}/" "${dst}/"
    else
        (cd "$src" && tar -cf - --exclude '.git' --exclude '.DS_Store' .) | (cd "$dst" && tar -xf -)
    fi
}

# Names of the skills this repo ships, derived from the repo itself.
stack_skill_names() {
    local d
    for d in "${STACK_SKILLS}"/*/; do
        [[ -f "${d}SKILL.md" ]] && basename "$d"
    done
}

# ============================================================
# Parse arguments
# ============================================================

MODE="full"
DRY_RUN=false
SKIP_SHELL=false
SKIP_DEPS=false
PROJECT_TARGET=""

print_help() {
    echo "Usage: bash install.sh [MODE] [OPTIONS]"
    echo ""
    echo "Modes (pick one):"
    echo "  --full             Skills + CLAUDE.md + settings + shell (default)"
    echo "  --skills           Install the skills to ~/.claude/skills/ only"
    echo "  --project [PATH]   Copy the stack into another project's .claude/ directory"
    echo "  --shell            Shell only: mise + runtimes, starship, zsh plugins, .zshrc"
    echo "  --uninstall        Remove installed skills and the .zshrc source line"
    echo ""
    echo "Options:"
    echo "  --dry-run          Show what would happen without changing anything"
    echo "  --skip-shell       Full install but skip mise/starship/zsh configuration"
    echo "  --skip-deps        Shell setup without installing mise/brew packages (configs only)"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash install.sh                          # Full install"
    echo "  bash install.sh --skills                 # Just the skills"
    echo "  bash install.sh --shell                  # Just the shell: mise, starship, zsh"
    echo "  bash install.sh --shell --dry-run        # Preview the shell setup"
    echo "  bash install.sh --project /path/to/app   # Copy the stack into another project"
    echo "  bash install.sh --project                # Copy the stack into the current directory"
    echo "  bash install.sh --full --dry-run         # Preview a full install"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)      MODE="full"; shift ;;
        --skills)    MODE="skills"; shift ;;
        --shell)     MODE="shell"; shift ;;
        --project)
            MODE="project"
            shift
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                PROJECT_TARGET="$1"
                shift
            fi
            ;;
        --uninstall) MODE="uninstall"; shift ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --skip-shell) SKIP_SHELL=true; shift ;;
        --skip-deps) SKIP_DEPS=true; shift ;;
        --help|-h)   print_help ;;
        *)           die "Unknown option: $1 (use --help for usage)" ;;
    esac
done

# ============================================================
# Uninstall
# ============================================================

do_uninstall() {
    print_banner
    log_step "Uninstalling Delavalom Stack..."

    local name removed=0
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if [[ -e "${USER_SKILLS}/${name}" ]]; then
            run_rm_r "${USER_SKILLS}/${name}"
            log_ok "Removed skill: ${name}"
            removed=$((removed + 1))
        fi
    done < <(stack_skill_names)
    [[ $removed -eq 0 ]] && log_info "No stack skills found in ${USER_SKILLS}"

    local zshrc="${HOME}/.zshrc"
    local marker="# delavalom-stack shell config"
    if [[ -f "$zshrc" ]] && grep -qF "$marker" "$zshrc"; then
        if $DRY_RUN; then
            log_dry "Would remove the delavalom-stack block from ${zshrc}"
        else
            cp "$zshrc" "${zshrc}.bak"
            grep -vF -e "$marker" -e "${SCRIPT_DIR}/shell/delavalom.zsh" "$zshrc" > "${zshrc}.tmp"
            mv "${zshrc}.tmp" "$zshrc"
            log_ok "Removed source line from .zshrc (backup at .zshrc.bak)"
        fi
    fi

    echo ""
    log_ok "Uninstall complete."
    log_info "Preserved (remove manually if needed):"
    echo -e "  ${DIM}~/.config/starship.toml${NC}"
    echo -e "  ${DIM}~/.config/mise/config.toml${NC}"
    echo -e "  ${DIM}mise-managed runtimes${NC}"
}

if [[ "$MODE" == "uninstall" ]]; then
    do_uninstall
    exit 0
fi

# ============================================================
# Prerequisites
# ============================================================

print_banner

if $DRY_RUN; then
    echo -e "  ${YELLOW}>>> DRY RUN MODE -- no changes will be made <<<${NC}"
    echo ""
fi

echo -e "  ${CYAN}Mode:${NC} ${BOLD}${MODE}${NC}"
echo ""

log_step "Checking prerequisites..."

if [[ "$MODE" == "shell" ]]; then
    [[ -d "${SCRIPT_DIR}/shell" ]] || die "shell/ not found at ${SCRIPT_DIR}/shell -- run this script from the delavalom-stack repo"
else
    [[ -d "$STACK_SKILLS" ]] || die "Skills not found at ${STACK_SKILLS} -- run this script from the delavalom-stack repo"

    if command -v claude &>/dev/null; then
        log_ok "Claude Code found: $(claude --version 2>/dev/null || echo unknown)"
    else
        log_warn "Claude Code CLI not found in PATH. Files will still be installed."
    fi
fi

# ============================================================
# Install: skills to ~/.claude/skills/
# ============================================================

install_skills() {
    log_step "Installing skills to ${USER_SKILLS}/..."
    run_mkdir "$USER_SKILLS"

    local backup_dir=""
    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local dst="${USER_SKILLS}/${name}"

        # Back up anything already there that isn't identical to what we ship.
        if [[ -e "$dst" || -L "$dst" ]]; then
            if [[ -d "$dst" && ! -L "$dst" ]] && diff -rq "${STACK_SKILLS}/${name}" "$dst" &>/dev/null; then
                : # already identical, nothing to preserve
            else
                if [[ -z "$backup_dir" ]]; then
                    backup_dir="${BACKUP_ROOT}/delavalom-stack-$(date +%Y%m%d_%H%M%S)"
                    run_mkdir "$backup_dir"
                fi
                if $DRY_RUN; then
                    log_dry "Would back up ${dst} -> ${backup_dir}/${name}"
                else
                    cp -R "$dst" "${backup_dir}/${name}"
                fi
                log_info "Backed up existing: ${name}"
            fi
        fi

        copy_tree "${STACK_SKILLS}/${name}" "$dst"
        log_ok "Skill: ${name}"
        INSTALLED_SKILLS=$((INSTALLED_SKILLS + 1))
    done < <(stack_skill_names)

    if [[ $INSTALLED_SKILLS -eq 0 ]]; then
        log_warn "No skills found in ${STACK_SKILLS}"
    else
        echo -e "  ${GREEN}${INSTALLED_SKILLS} skills installed${NC}"
    fi
    [[ -n "$backup_dir" ]] && log_info "Backups: ${backup_dir}"
}

# ============================================================
# Install: CLAUDE.md and settings.json (verify in place)
# ============================================================

verify_context() {
    log_step "Verifying stack context files..."

    if [[ -f "${STACK_CLAUDE}/CLAUDE.md" ]]; then
        log_ok "CLAUDE.md present ($(wc -l < "${STACK_CLAUDE}/CLAUDE.md" | tr -d ' ') lines)"
    else
        log_warn "CLAUDE.md not found -- the stack will lack project context"
    fi

    if [[ -f "${STACK_CLAUDE}/settings.json" ]]; then
        log_ok "settings.json present"
    else
        log_warn "settings.json not found"
    fi
}

# ============================================================
# Install: shell configuration
# ============================================================

install_shell() {
    log_step "Installing shell configuration..."

    local setup="${SCRIPT_DIR}/shell/setup.sh"
    if [[ ! -f "$setup" ]]; then
        log_warn "shell/setup.sh not found -- skipping shell setup"
        return
    fi

    # shell/setup.sh owns the shell logic (mise + runtimes, starship, zsh
    # plugins, .zshrc). Delegate so there is only one copy of it.
    local args=()
    $DRY_RUN && args+=(--dry-run)
    $SKIP_DEPS && args+=(--skip-deps)

    bash "$setup" "${args[@]+"${args[@]}"}" || log_warn "Shell setup exited with errors"
}

# ============================================================
# --project mode: copy the stack into another project
# ============================================================

do_project_install() {
    local target="${PROJECT_TARGET:-$(pwd)}"
    local abs_target
    abs_target="$(cd "$target" 2>/dev/null && pwd)" || die "Target directory does not exist: ${target}"
    [[ "$abs_target" == "$SCRIPT_DIR" ]] && die "Cannot use --project on the stack repo itself. Use --full instead."

    local target_claude="${abs_target}/.claude"
    log_step "Project install target: ${abs_target}"

    if [[ -d "$target_claude" ]]; then
        local backup_dir="${abs_target}/.claude.bak.$(date +%Y%m%d_%H%M%S)"
        if $DRY_RUN; then
            log_dry "cp -r ${target_claude} ${backup_dir}"
        else
            cp -r "$target_claude" "$backup_dir"
        fi
        log_ok "Backed up existing .claude/ to $(basename "$backup_dir")/"
    fi

    run_mkdir "${target_claude}/skills"

    log_step "Copying skills..."
    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        copy_tree "${STACK_SKILLS}/${name}" "${target_claude}/skills/${name}"
        log_ok "Skill: ${name}"
        INSTALLED_SKILLS=$((INSTALLED_SKILLS + 1))
    done < <(stack_skill_names)

    log_step "Copying context files..."
    [[ -f "${STACK_CLAUDE}/CLAUDE.md" ]] && { run_cp "${STACK_CLAUDE}/CLAUDE.md" "${target_claude}/CLAUDE.md"; log_ok "CLAUDE.md"; }
    [[ -f "${STACK_CLAUDE}/settings.json" ]] && { run_cp "${STACK_CLAUDE}/settings.json" "${target_claude}/settings.json"; log_ok "settings.json"; }
}

# ============================================================
# Run
# ============================================================

case "$MODE" in
    full)
        install_skills
        verify_context
        $SKIP_SHELL || install_shell
        ;;
    skills)
        install_skills
        ;;
    shell)
        install_shell
        ;;
    project)
        do_project_install
        ;;
esac

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${PURPLE}  +===================================================+${NC}"
echo -e "${PURPLE}  |                  INSTALL SUMMARY                  |${NC}"
echo -e "${PURPLE}  +===================================================+${NC}"
echo ""
[[ "$MODE" != "shell" ]] && echo -e "  ${BOLD}Skills:${NC}  ${INSTALLED_SKILLS}"
echo -e "  ${BOLD}Mode:${NC}    ${MODE}"
$DRY_RUN && echo -e "  ${YELLOW}(dry run -- nothing was changed)${NC}"
echo ""

if [[ "$MODE" == "full" || "$MODE" == "skills" ]]; then
    log_info "Restart Claude Code (or run /doctor) to pick up the new skills."
fi
if [[ "$MODE" == "shell" ]] || { [[ "$MODE" == "full" ]] && ! $SKIP_SHELL; }; then
    log_info "Run 'exec zsh' to load the shell configuration."
fi
echo ""
