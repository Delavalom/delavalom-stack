#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Delavalom Shell Setup
# Installs mise (tool manager), starship prompt, zsh plugins
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }

DRY_RUN=false
SKIP_DEPS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --skip-deps) SKIP_DEPS=true; shift ;;
        --help|-h)
            echo "Usage: bash shell/setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be installed"
            echo "  --skip-deps   Skip installing dependencies"
            echo "  --help        Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo -e "${BOLD}Delavalom Shell Setup${NC}"
echo ""

# ============================================================
# Install mise (the single tool manager)
# ============================================================
if ! $SKIP_DEPS; then
    log_step "Checking mise..."

    if command -v mise &>/dev/null || [ -x "$HOME/.local/bin/mise" ]; then
        MISE_VER=$("${HOME}/.local/bin/mise" --version 2>/dev/null || mise --version 2>/dev/null || echo "unknown")
        log_ok "mise already installed: ${MISE_VER}"
    else
        if $DRY_RUN; then
            log_info "[DRY] Would install mise via curl https://mise.run"
        else
            log_step "Installing mise..."
            curl -sSf https://mise.run | sh
            log_ok "mise installed to ~/.local/bin/mise"
        fi
    fi

    # Install all tools defined in mise.toml
    if [ -f "${STACK_DIR}/mise.toml" ]; then
        log_step "Installing runtimes via mise (node, python, go, rust, bun, java)..."
        if $DRY_RUN; then
            log_info "[DRY] Would run: mise install (from ${STACK_DIR}/mise.toml)"
        else
            # Copy mise.toml to global config if user wants it as default
            GLOBAL_MISE="${HOME}/.config/mise/config.toml"
            if [ ! -f "$GLOBAL_MISE" ]; then
                mkdir -p "$(dirname "$GLOBAL_MISE")"
                cp "${STACK_DIR}/mise.toml" "$GLOBAL_MISE"
                log_ok "Copied mise.toml to ~/.config/mise/config.toml (global defaults)"
            else
                log_info "Global mise config already exists. Merge manually if needed:"
                log_info "  ${STACK_DIR}/mise.toml -> ${GLOBAL_MISE}"
            fi

            # Install tools
            if [ -x "$HOME/.local/bin/mise" ]; then
                MISE_CMD="$HOME/.local/bin/mise"
            else
                MISE_CMD="mise"
            fi

            # Trust the config first
            "$MISE_CMD" trust "${STACK_DIR}/mise.toml" 2>/dev/null || true

            "$MISE_CMD" install --yes 2>/dev/null && log_ok "All runtimes installed via mise" || {
                log_warn "Some runtimes failed to install. Run 'mise install' manually."
            }
        fi
    fi
fi

# ============================================================
# Install shell dependencies via Homebrew
# ============================================================
if ! $SKIP_DEPS; then
    log_step "Checking shell dependencies..."

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not found. Install from https://brew.sh for shell plugins."
    else
        DEPS=(starship zsh-autosuggestions zsh-syntax-highlighting)
        for dep in "${DEPS[@]}"; do
            if brew list "$dep" &>/dev/null; then
                log_ok "$dep already installed"
            else
                if $DRY_RUN; then
                    log_info "[DRY] Would install: $dep"
                else
                    log_step "Installing $dep..."
                    brew install "$dep" && log_ok "Installed $dep" || log_warn "Failed to install $dep"
                fi
            fi
        done
    fi
fi

# ============================================================
# Install starship config
# ============================================================
log_step "Installing starship config..."

STARSHIP_CONFIG="${HOME}/.config/starship.toml"
STARSHIP_SRC="${SCRIPT_DIR}/starship.toml"

if [[ -f "$STARSHIP_CONFIG" ]]; then
    if diff -q "$STARSHIP_SRC" "$STARSHIP_CONFIG" &>/dev/null; then
        log_ok "starship.toml already up-to-date"
    else
        if $DRY_RUN; then
            log_info "[DRY] Would backup and replace ${STARSHIP_CONFIG}"
        else
            cp "$STARSHIP_CONFIG" "${STARSHIP_CONFIG}.bak"
            log_info "Backed up existing starship.toml to starship.toml.bak"
            cp "$STARSHIP_SRC" "$STARSHIP_CONFIG"
            log_ok "starship.toml installed"
        fi
    fi
else
    if $DRY_RUN; then
        log_info "[DRY] Would install ${STARSHIP_CONFIG}"
    else
        mkdir -p "$(dirname "$STARSHIP_CONFIG")"
        cp "$STARSHIP_SRC" "$STARSHIP_CONFIG"
        log_ok "starship.toml installed"
    fi
fi

# ============================================================
# Add source line to .zshrc
# ============================================================
log_step "Configuring .zshrc..."

ZSHRC="${HOME}/.zshrc"
SOURCE_LINE="source \"${SCRIPT_DIR}/delavalom.zsh\""
MARKER="# delavalom-stack shell config"

if [[ -f "$ZSHRC" ]] && grep -qF "$MARKER" "$ZSHRC"; then
    log_ok ".zshrc already configured"
else
    if $DRY_RUN; then
        log_info "[DRY] Would add source line to ${ZSHRC}"
    else
        {
            echo ""
            echo "$MARKER"
            echo "$SOURCE_LINE"
        } >> "$ZSHRC"
        log_ok "Added source line to .zshrc"
    fi
fi

# ============================================================
# Summary
# ============================================================
echo ""
if $DRY_RUN; then
    echo -e "${YELLOW}Dry run complete -- no changes made.${NC}"
else
    echo -e "${GREEN}${BOLD}Shell setup complete.${NC}"
    echo -e "  Restart your terminal or run: ${CYAN}source ~/.zshrc${NC}"
fi
echo ""
echo -e "  ${BOLD}What's configured:${NC}"
echo -e "    Mise           All runtimes (node, python, go, rust, bun, java)"
echo -e "    Starship       Gruvbox dark prompt with polyglot language segments"
echo -e "    ZSH plugins    Autosuggestions + syntax highlighting"
echo -e "    Dev aliases    cc, gs, k, dc, mi, etc."
echo -e "    Completions    kubectl, bun, mise"
echo -e "    History        50K entries with dedup and sharing"
echo ""
echo -e "  ${BOLD}Mise commands:${NC}"
echo -e "    ${CYAN}mise list${NC}                  Show installed tools"
echo -e "    ${CYAN}mise install${NC}               Install tools from mise.toml"
echo -e "    ${CYAN}mise use --global go@latest${NC} Add a tool globally"
echo -e "    ${CYAN}mise run <task>${NC}             Run a defined task"
echo ""
