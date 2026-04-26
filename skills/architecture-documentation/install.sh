#!/usr/bin/env bash
# Architecture Documentation Skill — Universal Installer
# Supports: Cline, Cursor, Inceptor, Generic (AGENTS.md)
# Works when run locally OR piped: curl -fsSL ... | bash

set -eo pipefail

SKILL_NAME="architecture-documentation"
SKILL_VERSION="1.0.0"
GITHUB_RAW="https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/${SKILL_NAME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[skill]${NC} $*"; }
ok()  { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*"; exit 1; }

# Detect how we were invoked: local file vs piped
detect_mode() {
    if [[ -t 0 ]]; then
        # stdin is a terminal → running locally
        echo "local"
    else
        # stdin is a pipe → curl | bash
        echo "piped"
    fi
}

# Get the directory containing this script (only works in local mode)
get_script_dir() {
    local src="${BASH_SOURCE[0]:-}"
    if [[ -z "$src" ]]; then
        echo ""
        return
    fi
    cd "$(dirname "$src")" && pwd
}

# Fetch a remote file to stdout
fetch() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$url"
    else
        err "Need curl or wget to download skill files"
    fi
}

# Copy or fetch rules.md content into target file
install_rules() {
    local dest="$1"
    local mode="$2"

    if [[ "$mode" == "local" ]]; then
        local script_dir
        script_dir=$(get_script_dir)
        if [[ -f "$script_dir/rules.md" ]]; then
            cat "$script_dir/rules.md"
        else
            err "rules.md not found in $script_dir"
        fi
    else
        fetch "${GITHUB_RAW}/rules.md"
    fi > "$dest"
}

# Append or create target file
install_to_file() {
    local dest="$1"
    local mode="$2"

    if [[ -f "$dest" ]]; then
        if grep -q "Architecture Documentation Skill" "$dest" 2>/dev/null; then
            warn "$dest already contains this skill. Skipping."
            return 1
        fi
        {
            echo ""
            echo "# --- Architecture Documentation Skill (v${SKILL_VERSION}) ---"
            install_rules /dev/stdout "$mode"
            echo "# --- End Architecture Documentation Skill ---"
        } >> "$dest"
    else
        install_rules "$dest" "$mode"
    fi
    return 0
}

install_cline() {
    log "Installing for Cline → .clinerules"
    install_to_file ".clinerules" "$1"
    ok "Cline skill installed."
}

install_cursor() {
    log "Installing for Cursor → .cursorrules"
    install_to_file ".cursorrules" "$1"
    ok "Cursor skill installed."
}

install_inceptor() {
    local dest="${INCEPTOR_SKILLS_DIR:-$HOME/.inceptor/skills}"
    log "Installing for Inceptor → $dest/$SKILL_NAME"
    mkdir -p "$dest"

    if [[ -d "$dest/$SKILL_NAME" ]]; then
        warn "Overwriting existing skill..."
        rm -rf "$dest/$SKILL_NAME"
    fi
    mkdir -p "$dest/$SKILL_NAME"

    local mode="$1"
    local files="README.md install.sh manifest.json render.sh.template rules.md skill.md"

    for f in $files; do
        if [[ "$mode" == "local" ]]; then
            local script_dir
            script_dir=$(get_script_dir)
            cp "$script_dir/$f" "$dest/$SKILL_NAME/$f"
        else
            fetch "${GITHUB_RAW}/$f" > "$dest/$SKILL_NAME/$f"
        fi
    done

    chmod +x "$dest/$SKILL_NAME/install.sh"
    ok "Inceptor skill installed at $dest/$SKILL_NAME"
}

install_generic() {
    log "Installing generic agent rules → AGENTS.md"
    install_to_file "AGENTS.md" "$1"
    ok "Generic agent rules installed."
}

detect_target() {
    if [[ -n "${1:-}" ]]; then
        echo "$1"
        return
    fi
    if [[ -d ".cline" ]] || [[ -f ".clinerules" ]]; then
        echo "cline"
    elif [[ -d ".cursor" ]] || [[ -f ".cursorrules" ]]; then
        echo "cursor"
    elif [[ -d ".inceptor" ]] || [[ -d "inceptor" ]]; then
        echo "inceptor"
    else
        echo "generic"
    fi
}

main() {
    echo "=========================================="
    echo "  Architecture Documentation Skill v${SKILL_VERSION}"
    echo "=========================================="
    echo ""

    local mode
    mode=$(detect_mode)
    log "Mode: $mode"

    local target
    target=$(detect_target "${1:-}")
    log "Target: $target"
    echo ""

    case "$target" in
        cline)      install_cline "$mode" ;;
        cursor)     install_cursor "$mode" ;;
        inceptor)   install_inceptor "$mode" ;;
        generic)    install_generic "$mode" ;;
        *)          err "Unknown target: $target" ;;
    esac

    echo ""
    ok "Installation complete!"
    echo ""
    log "Trigger phrases:"
    echo "  - create architecture docs"
    echo "  - document the system architecture"
    echo "  - create system diagrams"
    echo "  - add deployment docs"
    echo "  - document the integration flow"
    echo ""
}

main "$@"
