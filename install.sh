#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Delavalom Stack Installer v2.0.0
# Production-ready setup for the complete Claude Code workflow
# ============================================================

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
PROJECT_CLAUDE="${SCRIPT_DIR}/.claude"
SKILLS_DIR="${CLAUDE_HOME}/skills"

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

# Counters
INSTALLED_AGENTS=0
INSTALLED_SKILLS=0
INSTALLED_HOOKS=0
INSTALLED_PLUGINS=0
FAILED_PLUGINS=0
PLUGIN_FAILURES=()

# ============================================================
# Helpers
# ============================================================

print_banner() {
    echo -e "${PURPLE}"
    echo "  +===================================================+"
    echo "  |         DELAVALOM STACK INSTALLER                  |"
    echo "  |         v${VERSION} -- Production-Ready Setup           |"
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

# DRY_RUN-aware wrappers
run_cmd() {
    if $DRY_RUN; then
        log_dry "$*"
    else
        "$@"
    fi
}

run_mkdir() {
    if $DRY_RUN; then
        log_dry "mkdir -p $1"
    else
        mkdir -p "$1"
    fi
}

run_cp() {
    if $DRY_RUN; then
        log_dry "cp $1 -> $2"
    else
        cp "$1" "$2"
    fi
}

run_cp_r() {
    if $DRY_RUN; then
        log_dry "cp -r $1 -> $2"
    else
        cp -r "$1" "$2"
    fi
}

run_rm() {
    if $DRY_RUN; then
        log_dry "rm -f $1"
    else
        rm -f "$1"
    fi
}

run_rm_r() {
    if $DRY_RUN; then
        log_dry "rm -rf $1"
    else
        rm -rf "$1"
    fi
}

# ============================================================
# External plugin definitions
# ============================================================

PLUGIN_NAMES=(
    "superpowers"
    "gstack"
    "impeccable"
    "oh-my-claudecode"
    "marketingskills"
    "no-use-effect"
    "everything-claude-code"
)

PLUGIN_URLS=(
    "https://github.com/obra/superpowers.git"
    "https://github.com/garrytan/gstack.git"
    "https://github.com/pbakaus/impeccable.git"
    "https://github.com/Yeachan-Heo/oh-my-claudecode.git"
    "https://github.com/coreyhaines31/marketingskills.git"
    "https://github.com/alejandrobailo/no-use-effect.git"
    "https://github.com/affaan-m/everything-claude-code.git"
)

# Agents by scope
USER_AGENTS=(delavalom-reviewer delavalom-debugger delavalom-researcher)
PROJECT_AGENTS=(delavalom-k8s-ops delavalom-data-eng delavalom-frontend delavalom-content)

# ============================================================
# Parse arguments
# ============================================================

MODE="full"
DRY_RUN=false
SKIP_PLUGINS=false
PROJECT_TARGET=""

print_help() {
    echo "Usage: bash install.sh [MODE] [OPTIONS]"
    echo ""
    echo "Modes (pick one):"
    echo "  --full             Full install: agents + skills + hooks + MCP + settings + plugins (default)"
    echo "  --project [PATH]   Copy stack into another project's .claude/ directory"
    echo "  --user             Install user-level agents to ~/.claude/agents/ only"
    echo "  --minimal          Agents + CLAUDE.md only, no plugins"
    echo "  --agents           Install only the 7 custom sub-agents"
    echo "  --uninstall        Remove all Delavalom-specific files"
    echo ""
    echo "Options:"
    echo "  --dry-run          Show what would be installed without doing it"
    echo "  --skip-plugins     Full install but skip external plugin cloning"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash install.sh                          # Full install with all plugins"
    echo "  bash install.sh --full --skip-plugins    # Full install, no external plugins"
    echo "  bash install.sh --project /path/to/app   # Copy stack into another project"
    echo "  bash install.sh --project                # Copy stack into current directory"
    echo "  bash install.sh --dry-run                # Preview what would happen"
    echo "  bash install.sh --minimal --dry-run      # Preview minimal install"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            MODE="full"; shift ;;
        --project)
            MODE="project"
            shift
            # Next argument is the target path if it exists and is not a flag
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                PROJECT_TARGET="$1"
                shift
            fi
            ;;
        --user)
            MODE="user"; shift ;;
        --minimal)
            MODE="minimal"; shift ;;
        --agents)
            MODE="agents"; shift ;;
        --uninstall)
            MODE="uninstall"; shift ;;
        --dry-run)
            DRY_RUN=true; shift ;;
        --skip-plugins)
            SKIP_PLUGINS=true; shift ;;
        --help|-h)
            print_help ;;
        *)
            die "Unknown option: $1 (use --help for usage)" ;;
    esac
done

# ============================================================
# Uninstall
# ============================================================

do_uninstall() {
    print_banner
    log_step "Uninstalling Delavalom Stack..."

    # Remove user-level agents
    for agent in "${USER_AGENTS[@]}"; do
        if [[ -f "${CLAUDE_HOME}/agents/${agent}.md" ]]; then
            run_rm "${CLAUDE_HOME}/agents/${agent}.md"
            log_ok "Removed user agent: ${agent}"
        fi
    done

    # Remove project-level agents
    for agent in "${PROJECT_AGENTS[@]}"; do
        if [[ -f "${PROJECT_CLAUDE}/agents/${agent}.md" ]]; then
            run_rm "${PROJECT_CLAUDE}/agents/${agent}.md"
            log_ok "Removed project agent: ${agent}"
        fi
    done

    # Remove external plugins
    for name in "${PLUGIN_NAMES[@]}"; do
        if [[ -d "${SKILLS_DIR}/${name}" ]]; then
            run_rm_r "${SKILLS_DIR}/${name}"
            log_ok "Removed plugin: ${name}"
        fi
    done

    # Remove custom skills
    for skill_dir in "${PROJECT_CLAUDE}/skills/delavalom-"*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            run_rm_r "$skill_dir"
            log_ok "Removed custom skill: ${skill_name}"
        fi
    done

    echo ""
    log_ok "Uninstall complete."
    log_info "The following were preserved (remove manually if needed):"
    echo -e "  ${DIM}${PROJECT_CLAUDE}/CLAUDE.md${NC}"
    echo -e "  ${DIM}${PROJECT_CLAUDE}/settings.json${NC}"
    echo -e "  ${DIM}${PROJECT_CLAUDE}/mcp.json${NC}"
    echo -e "  ${DIM}${PROJECT_CLAUDE}/hooks/${NC}"
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

if ! command -v git &>/dev/null; then
    die "git is required but not found in PATH"
fi

if ! command -v claude &>/dev/null; then
    log_warn "Claude Code CLI not found in PATH. Files will still be installed."
else
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    log_ok "Claude Code found: ${CLAUDE_VERSION}"
fi

# Verify source files exist
if [[ ! -d "$PROJECT_CLAUDE" ]]; then
    die "Source directory not found: ${PROJECT_CLAUDE} -- run this script from the delavalom-stack repo"
fi

# ============================================================
# Install: user-level agents
# ============================================================

install_user_agents() {
    log_step "Installing user-level agents to ~/.claude/agents/..."
    run_mkdir "${CLAUDE_HOME}/agents"

    for agent in "${USER_AGENTS[@]}"; do
        local src="${PROJECT_CLAUDE}/agents/${agent}.md"
        local dst="${CLAUDE_HOME}/agents/${agent}.md"
        if [[ -f "$src" ]]; then
            run_cp "$src" "$dst"
            log_ok "User agent: ${agent}"
            INSTALLED_AGENTS=$((INSTALLED_AGENTS + 1))
        else
            log_warn "Source not found: ${src}"
        fi
    done
}

# ============================================================
# Install: project-level agents (verify in-place)
# ============================================================

install_project_agents() {
    log_step "Verifying project-level agents in .claude/agents/..."

    for agent in "${PROJECT_AGENTS[@]}"; do
        local src="${PROJECT_CLAUDE}/agents/${agent}.md"
        if [[ -f "$src" ]]; then
            log_ok "Project agent: ${agent} (in-place)"
            INSTALLED_AGENTS=$((INSTALLED_AGENTS + 1))
        else
            log_warn "Project agent missing: ${agent}"
        fi
    done
}

# ============================================================
# Install: CLAUDE.md
# ============================================================

install_claude_md() {
    log_step "Verifying master CLAUDE.md..."
    if [[ -f "${PROJECT_CLAUDE}/CLAUDE.md" ]]; then
        local lines
        lines=$(wc -l < "${PROJECT_CLAUDE}/CLAUDE.md" | tr -d ' ')
        log_ok "CLAUDE.md present (${lines} lines)"
    else
        log_warn "CLAUDE.md not found -- stack will lack full context"
    fi
}

# ============================================================
# Install: custom skills
# ============================================================

install_custom_skills() {
    log_step "Verifying custom skills..."

    for skill_dir in "${PROJECT_CLAUDE}/skills/delavalom-"*/; do
        if [[ -d "$skill_dir" ]] && [[ -f "${skill_dir}/SKILL.md" ]]; then
            local skill_name
            skill_name=$(basename "$skill_dir")
            log_ok "Custom skill: ${skill_name}"
            INSTALLED_SKILLS=$((INSTALLED_SKILLS + 1))
        fi
    done

    if [[ $INSTALLED_SKILLS -eq 0 ]]; then
        log_warn "No custom skills found in ${PROJECT_CLAUDE}/skills/"
    else
        echo -e "  ${GREEN}${INSTALLED_SKILLS} custom skills verified${NC}"
    fi
}

# ============================================================
# Install: hooks
# ============================================================

install_hooks() {
    log_step "Verifying hooks configuration..."

    if [[ -f "${PROJECT_CLAUDE}/hooks/hooks.json" ]]; then
        log_ok "hooks.json present"
        INSTALLED_HOOKS=$((INSTALLED_HOOKS + 1))
    else
        log_warn "hooks.json not found"
    fi
}

# ============================================================
# Install: MCP config
# ============================================================

install_mcp() {
    log_step "Verifying MCP configuration..."

    if [[ -f "${PROJECT_CLAUDE}/mcp.json" ]]; then
        local server_count="?"
        if command -v python3 &>/dev/null; then
            server_count=$(python3 -c "
import json, sys
try:
    data = json.load(open('${PROJECT_CLAUDE}/mcp.json'))
    print(len(data.get('mcpServers', {})))
except Exception:
    print('?')
" 2>/dev/null || echo "?")
        fi
        log_ok "MCP config present (${server_count} servers)"
    else
        log_warn "mcp.json not found"
    fi
}

# ============================================================
# Install: settings (agent teams flag)
# ============================================================

install_settings() {
    log_step "Configuring settings.json..."

    local settings_file="${PROJECT_CLAUDE}/settings.json"

    if $DRY_RUN; then
        log_dry "Would enable agent teams in ${settings_file}"
        return
    fi

    if [[ -f "$settings_file" ]] && command -v python3 &>/dev/null; then
        python3 -c "
import json
with open('${settings_file}', 'r') as f:
    settings = json.load(f)
settings.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
with open('${settings_file}', 'w') as f:
    json.dump(settings, f, indent=2)
" 2>/dev/null && log_ok "Agent teams enabled in settings.json" || {
            log_warn "Could not update settings.json with python3"
        }
    elif [[ ! -f "$settings_file" ]]; then
        echo '{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }' > "$settings_file"
        log_ok "Created settings.json with agent teams enabled"
    else
        log_warn "python3 not found -- settings.json not updated"
    fi
}

# ============================================================
# Install: external plugins
# ============================================================

install_plugins() {
    log_step "Installing external plugins to ~/.claude/skills/..."
    run_mkdir "$SKILLS_DIR"

    local i
    for i in "${!PLUGIN_NAMES[@]}"; do
        local name="${PLUGIN_NAMES[$i]}"
        local dest="${SKILLS_DIR}/${name}"
        local url="${PLUGIN_URLS[$i]}"

        if [[ -d "$dest" ]]; then
            log_ok "Plugin already installed: ${name} (skipped)"
            INSTALLED_PLUGINS=$((INSTALLED_PLUGINS + 1))
            continue
        fi

        if $DRY_RUN; then
            log_dry "git clone --depth 1 ${url} ${dest}"
            INSTALLED_PLUGINS=$((INSTALLED_PLUGINS + 1))
            continue
        fi

        echo -e "  ${CYAN}Cloning ${name}...${NC}"
        if git clone --depth 1 "$url" "$dest" 2>/dev/null; then
            log_ok "Plugin installed: ${name}"
            INSTALLED_PLUGINS=$((INSTALLED_PLUGINS + 1))

            # gstack needs post-clone setup
            if [[ "$name" == "gstack" ]] && [[ -x "${dest}/setup" ]]; then
                echo -e "  ${CYAN}Running gstack setup...${NC}"
                if (cd "$dest" && ./setup) 2>/dev/null; then
                    log_ok "gstack setup complete"
                else
                    log_warn "gstack setup script failed (plugin still usable)"
                fi
            fi
        else
            log_err "Failed to clone: ${name} (${url})"
            FAILED_PLUGINS=$((FAILED_PLUGINS + 1))
            PLUGIN_FAILURES+=("$name")
        fi
    done

    echo -e "  ${GREEN}${INSTALLED_PLUGINS}/${#PLUGIN_NAMES[@]} plugins ready${NC}"
}

# ============================================================
# --project mode: copy stack into another project
# ============================================================

do_project_install() {
    # Resolve target directory
    local target
    if [[ -n "$PROJECT_TARGET" ]]; then
        target="$PROJECT_TARGET"
    else
        target="$(pwd)"
    fi

    # Don't install into self
    local abs_target
    abs_target="$(cd "$target" 2>/dev/null && pwd)" || die "Target directory does not exist: ${target}"
    if [[ "$abs_target" == "$SCRIPT_DIR" ]]; then
        die "Cannot use --project to install into the stack repo itself. Use --full instead."
    fi

    local target_claude="${abs_target}/.claude"

    log_step "Project install target: ${abs_target}"

    # Backup existing .claude/ if present
    if [[ -d "$target_claude" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_dir="${abs_target}/.claude.bak.${timestamp}"
        log_info "Backing up existing .claude/ to .claude.bak.${timestamp}/"
        if $DRY_RUN; then
            log_dry "cp -r ${target_claude} ${backup_dir}"
        else
            cp -r "$target_claude" "$backup_dir"
        fi
        log_ok "Backup created"
    fi

    # Create directory structure
    run_mkdir "${target_claude}/agents"
    run_mkdir "${target_claude}/skills"
    run_mkdir "${target_claude}/hooks"

    # Copy agents (all 7)
    log_step "Copying agents..."
    for agent in "${USER_AGENTS[@]}" "${PROJECT_AGENTS[@]}"; do
        local src="${PROJECT_CLAUDE}/agents/${agent}.md"
        if [[ -f "$src" ]]; then
            run_cp "$src" "${target_claude}/agents/${agent}.md"
            log_ok "Agent: ${agent}"
            INSTALLED_AGENTS=$((INSTALLED_AGENTS + 1))
        else
            log_warn "Agent source missing: ${agent}"
        fi
    done

    # Copy custom skills
    log_step "Copying custom skills..."
    for skill_dir in "${PROJECT_CLAUDE}/skills/delavalom-"*/; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name
            skill_name=$(basename "$skill_dir")
            run_cp_r "$skill_dir" "${target_claude}/skills/${skill_name}"
            log_ok "Skill: ${skill_name}"
            INSTALLED_SKILLS=$((INSTALLED_SKILLS + 1))
        fi
    done

    # Copy hooks
    log_step "Copying hooks..."
    if [[ -f "${PROJECT_CLAUDE}/hooks/hooks.json" ]]; then
        run_cp "${PROJECT_CLAUDE}/hooks/hooks.json" "${target_claude}/hooks/hooks.json"
        log_ok "hooks.json"
        INSTALLED_HOOKS=$((INSTALLED_HOOKS + 1))
    fi

    # Copy CLAUDE.md
    log_step "Copying CLAUDE.md..."
    if [[ -f "${PROJECT_CLAUDE}/CLAUDE.md" ]]; then
        run_cp "${PROJECT_CLAUDE}/CLAUDE.md" "${target_claude}/CLAUDE.md"
        log_ok "CLAUDE.md"
    fi

    # Copy settings.json
    log_step "Copying settings.json..."
    if [[ -f "${PROJECT_CLAUDE}/settings.json" ]]; then
        run_cp "${PROJECT_CLAUDE}/settings.json" "${target_claude}/settings.json"
        log_ok "settings.json"
    fi

    # Copy mcp.json
    log_step "Copying mcp.json..."
    if [[ -f "${PROJECT_CLAUDE}/mcp.json" ]]; then
        run_cp "${PROJECT_CLAUDE}/mcp.json" "${target_claude}/mcp.json"
        log_ok "mcp.json"
    fi

    log_info "External plugins are NOT installed in --project mode."
    log_info "Run 'bash install.sh --full' from the stack repo to install plugins to ~/.claude/skills/."
}

# ============================================================
# Mode dispatch
# ============================================================

case "$MODE" in
    full)
        install_user_agents
        install_project_agents
        install_claude_md
        install_custom_skills
        install_hooks
        install_mcp
        install_settings
        if ! $SKIP_PLUGINS; then
            install_plugins
        else
            log_info "Skipping external plugins (--skip-plugins)"
        fi
        ;;
    project)
        do_project_install
        ;;
    user)
        install_user_agents
        ;;
    minimal)
        install_user_agents
        install_project_agents
        install_claude_md
        ;;
    agents)
        install_user_agents
        install_project_agents
        ;;
esac

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${PURPLE}====================================================${NC}"
if $DRY_RUN; then
    echo -e "${BOLD}${YELLOW}  DRY RUN COMPLETE -- No changes were made${NC}"
else
    echo -e "${BOLD}${GREEN}  DELAVALOM STACK INSTALLED SUCCESSFULLY${NC}"
fi
echo -e "${PURPLE}====================================================${NC}"
echo ""
echo -e "  ${CYAN}Mode:${NC}       ${BOLD}${MODE}${NC}"
echo -e "  ${CYAN}Version:${NC}    ${VERSION}"

if [[ $INSTALLED_AGENTS -gt 0 ]]; then
    echo -e "  ${CYAN}Agents:${NC}     ${INSTALLED_AGENTS} installed (${#USER_AGENTS[@]} user + ${#PROJECT_AGENTS[@]} project)"
fi
if [[ $INSTALLED_SKILLS -gt 0 ]]; then
    echo -e "  ${CYAN}Skills:${NC}     ${INSTALLED_SKILLS} custom skills"
fi
if [[ $INSTALLED_HOOKS -gt 0 ]]; then
    echo -e "  ${CYAN}Hooks:${NC}      Workflow governance active"
fi
if [[ $INSTALLED_PLUGINS -gt 0 ]]; then
    echo -e "  ${CYAN}Plugins:${NC}    ${INSTALLED_PLUGINS}/${#PLUGIN_NAMES[@]} external plugins"
fi

if [[ "$MODE" == "full" ]] || [[ "$MODE" == "minimal" ]] || [[ "$MODE" == "project" ]]; then
    echo -e "  ${CYAN}Config:${NC}     CLAUDE.md + settings.json + mcp.json"
fi

# Report failures
if [[ $FAILED_PLUGINS -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}Failures:${NC}   ${FAILED_PLUGINS} plugin(s) failed to install:"
    for fail in "${PLUGIN_FAILURES[@]}"; do
        echo -e "              ${RED}- ${fail}${NC}"
    done
    echo -e "  ${YELLOW}Re-run the installer or clone manually.${NC}"
fi

echo ""
echo -e "  ${BOLD}Quick start:${NC}"
echo -e "    ${CYAN}claude agents${NC}                         -- List all agents"
echo -e "    ${CYAN}claude --agent delavalom-reviewer${NC}     -- Start a review session"
echo -e "    ${CYAN}claude --agent delavalom-debugger${NC}     -- Debug with root cause analysis"
echo -e "    ${CYAN}claude --agent delavalom-researcher${NC}   -- Research with web search"
echo ""
echo -e "  ${BOLD}The Delavalom Pipeline:${NC}"
echo -e "    ${PURPLE}THINK${NC} -> ${BLUE}RESEARCH${NC} -> ${CYAN}PLAN${NC} -> ${GREEN}BUILD${NC} -> ${YELLOW}REVIEW${NC} -> ${RED}SECURE${NC} -> ${PURPLE}SHIP${NC} -> ${BLUE}REFLECT${NC}"
echo ""
