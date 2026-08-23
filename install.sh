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
PROJECT_TARGET=""

print_help() {
    echo "Usage: bash install.sh [MODE] [OPTIONS]"
    echo ""
    echo "Modes (pick one):"
    echo "  --full             Skills + CLAUDE.md + settings + shell (default)"
    echo "  --skills           Install the skills to ~/.claude/skills/ only"
    echo "  --project [PATH]   Copy the stack into another project's .claude/ directory"
    echo "  --uninstall        Remove installed skills and the .zshrc source line"
    echo ""
    echo "Options:"
    echo "  --dry-run          Show what would happen without changing anything"
    echo "  --skip-shell       Full install but skip mise/starship/zsh configuration"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash install.sh                          # Full install"
    echo "  bash install.sh --skills                 # Just the skills"
    echo "  bash install.sh --project /path/to/app   # Copy the stack into another project"
    echo "  bash install.sh --project                # Copy the stack into the current directory"
    echo "  bash install.sh --full --dry-run         # Preview a full install"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)      MODE="full"; shift ;;
        --skills)    MODE="skills"; shift ;;
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

[[ -d "$STACK_SKILLS" ]] || die "Skills not found at ${STACK_SKILLS} -- run this script from the delavalom-stack repo"

if command -v claude &>/dev/null; then
    log_ok "Claude Code found: $(claude --version 2>/dev/null || echo unknown)"
else
    log_warn "Claude Code CLI not found in PATH. Files will still be installed."
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

    local shell_dir="${SCRIPT_DIR}/shell"
    if [[ ! -d "$shell_dir" ]]; then
        log_warn "shell/ directory not found -- skipping shell setup"
        return
    fi

    # mise: single tool manager for all runtimes
    if command -v mise &>/dev/null || [[ -x "$HOME/.local/bin/mise" ]]; then
        log_ok "mise already installed: $("$HOME/.local/bin/mise" --version 2>/dev/null || mise --version 2>/dev/null || echo unknown)"
    else
        if $DRY_RUN; then
            log_dry "Would install mise via curl https://mise.run"
        else
            log_step "Installing mise (node, python, go, rust, bun, java)..."
            curl -sSf https://mise.run | sh 2>/dev/null && log_ok "mise installed" \
                || log_warn "mise install failed -- install manually: curl https://mise.run | sh"
        fi
    fi

    local mise_toml="${SCRIPT_DIR}/mise.toml"
    local global_mise="${HOME}/.config/mise/config.toml"

    if [[ -f "$mise_toml" ]]; then
        if $DRY_RUN; then
            log_dry "Would copy mise.toml to ${global_mise}"
        elif [[ ! -f "$global_mise" ]]; then
            mkdir -p "${HOME}/.config/mise"
            cp "$mise_toml" "$global_mise"
            log_ok "mise.toml installed as global config"
        else
            log_info "Global mise config already exists (${global_mise})"
        fi

        local mise_cmd=""
        [[ -x "$HOME/.local/bin/mise" ]] && mise_cmd="$HOME/.local/bin/mise"
        command -v mise &>/dev/null && mise_cmd="mise"

        if [[ -n "$mise_cmd" ]]; then
            if $DRY_RUN; then
                log_dry "Would run: mise install"
            else
                log_step "Installing runtimes via mise..."
                "$mise_cmd" trust "$mise_toml" 2>/dev/null || true
                "$mise_cmd" install --yes 2>/dev/null && log_ok "All runtimes installed via mise" \
                    || log_warn "Some runtimes failed. Run 'mise install' manually after setup."
            fi
        fi
    fi

    # starship prompt
    local starship_src="${shell_dir}/starship.toml"
    local starship_dst="${HOME}/.config/starship.toml"

    if [[ -f "$starship_src" ]]; then
        if $DRY_RUN; then
            log_dry "Would install starship.toml to ${starship_dst}"
        else
            mkdir -p "${HOME}/.config"
            if [[ -f "$starship_dst" ]] && ! diff -q "$starship_src" "$starship_dst" &>/dev/null; then
                cp "$starship_dst" "${starship_dst}.bak"
                log_info "Backed up existing starship.toml"
            fi
            cp "$starship_src" "$starship_dst"
            log_ok "starship.toml installed (gruvbox dark)"
        fi
    fi

    # .zshrc source line
    local zshrc="${HOME}/.zshrc"
    local marker="# delavalom-stack shell config"

    if [[ -f "$zshrc" ]] && grep -qF "$marker" "$zshrc"; then
        log_ok ".zshrc already configured"
    elif $DRY_RUN; then
        log_dry "Would add source line to ${zshrc}"
    else
        {
            echo ""
            echo "$marker"
            echo "source \"${shell_dir}/delavalom.zsh\""
        } >> "$zshrc"
        log_ok "Added delavalom.zsh source line to .zshrc"
    fi

    local missing_deps=()
    command -v starship &>/dev/null || missing_deps+=(starship)
    if command -v brew &>/dev/null; then
        brew list zsh-autosuggestions &>/dev/null || missing_deps+=(zsh-autosuggestions)
        brew list zsh-syntax-highlighting &>/dev/null || missing_deps+=(zsh-syntax-highlighting)
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing shell deps: ${missing_deps[*]}"
        log_info "Install with: brew install ${missing_deps[*]}"
    fi
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
echo -e "  ${BOLD}Skills:${NC}  ${INSTALLED_SKILLS}"
echo -e "  ${BOLD}Mode:${NC}    ${MODE}"
$DRY_RUN && echo -e "  ${YELLOW}(dry run -- nothing was changed)${NC}"
echo ""

if [[ "$MODE" == "full" || "$MODE" == "skills" ]]; then
    log_info "Restart Claude Code (or run /doctor) to pick up the new skills."
fi
if [[ "$MODE" == "full" ]] && ! $SKIP_SHELL; then
    log_info "Run 'exec zsh' to load the shell configuration."
fi
echo ""
