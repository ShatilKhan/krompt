#!/usr/bin/env bash
# Architecture Documentation Skill — Universal Installer
# Supports: Cline, Cursor, Inceptor, Generic (AGENTS.md)
# Usage: curl -fsSL ... | bash  OR  bash install.sh [target]

set -euo pipefail

SKILL_NAME="architecture-documentation"
SKILL_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[skill]${NC} $*"; }
ok()  { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*"; exit 1; }

detect_target() {
    if [[ -n "${1:-}" ]]; then
        echo "$1"
        return
    fi

    # Auto-detect based on project files
    if [[ -d ".cline" ]] || [[ -f ".clinerules" ]]; then
        echo "cline"
    elif [[ -d ".cursor" ]] || [[ -f ".cursorrules" ]]; then
        echo "cursor"
    elif [[ -d ".inceptor" ]] || [[ -d "inceptor" ]]; then
        echo "inceptor"
    elif git rev-parse --git-dir > /dev/null 2>&1; then
        echo "generic"
    else
        echo "generic"
    fi
}

install_cline() {
    local dest=".clinerules"
    log "Installing for Cline → $dest"

    if [[ -f "$dest" ]]; then
        # Check if already installed
        if grep -q "Architecture Documentation Skill" "$dest" 2>/dev/null; then
            warn "$dest already contains this skill. Skipping."
            return
        fi
        echo "" >> "$dest"
        echo "# --- Architecture Documentation Skill (v$SKILL_VERSION) ---" >> "$dest"
        cat "$SCRIPT_DIR/rules.md" >> "$dest"
        echo "# --- End Architecture Documentation Skill ---" >> "$dest"
    else
        cp "$SCRIPT_DIR/rules.md" "$dest"
    fi

    ok "Cline skill installed. Active on next Cline session."
}

install_cursor() {
    local dest=".cursorrules"
    log "Installing for Cursor → $dest"

    if [[ -f "$dest" ]]; then
        if grep -q "Architecture Documentation Skill" "$dest" 2>/dev/null; then
            warn "$dest already contains this skill. Skipping."
            return
        fi
        echo "" >> "$dest"
        echo "# --- Architecture Documentation Skill (v$SKILL_VERSION) ---" >> "$dest"
        cat "$SCRIPT_DIR/rules.md" >> "$dest"
        echo "# --- End Architecture Documentation Skill ---" >> "$dest"
    else
        cp "$SCRIPT_DIR/rules.md" "$dest"
    fi

    ok "Cursor skill installed. Active on next Cursor session."
}

install_inceptor() {
    local dest="${INCEPTOR_SKILLS_DIR:-$HOME/.inceptor/skills}"
    log "Installing for Inceptor → $dest/$SKILL_NAME"

    mkdir -p "$dest"

    if [[ -d "$dest/$SKILL_NAME" ]]; then
        warn "Skill already exists at $dest/$SKILL_NAME. Overwriting..."
        rm -rf "$dest/$SKILL_NAME"
    fi

    cp -r "$SCRIPT_DIR" "$dest/$SKILL_NAME"
    ok "Inceptor skill installed at $dest/$SKILL_NAME"
}

install_generic() {
    local dest="AGENTS.md"
    log "Installing generic agent rules → $dest"

    if [[ -f "$dest" ]]; then
        if grep -q "Architecture Documentation Skill" "$dest" 2>/dev/null; then
            warn "$dest already contains this skill. Skipping."
            return
        fi
        echo "" >> "$dest"
        echo "# --- Architecture Documentation Skill (v$SKILL_VERSION) ---" >> "$dest"
        cat "$SCRIPT_DIR/rules.md" >> "$dest"
        echo "# --- End Architecture Documentation Skill ---" >> "$dest"
    else
        cp "$SCRIPT_DIR/rules.md" "$dest"
    fi

    ok "Generic agent rules installed at $dest"
}

main() {
    echo "=========================================="
    echo "  Architecture Documentation Skill v$SKILL_VERSION"
    echo "=========================================="
    echo ""

    local target
    target=$(detect_target "${1:-}")

    log "Detected target: $target"
    echo ""

    case "$target" in
        cline)
            install_cline
            ;;
        cursor)
            install_cursor
            ;;
        inceptor)
            install_inceptor
            ;;
        generic)
            install_generic
            ;;
        *)
            err "Unknown target: $target. Use: cline | cursor | inceptor | generic"
            ;;
    esac

    echo ""
    ok "Installation complete!"
    echo ""
    log "Trigger phrases to activate the skill:"
    grep '"' "$SCRIPT_DIR/manifest.json" | grep -E 'create|document|write' | sed 's/.*"\(.*\)".*/  - \1/' || true
    echo ""
}

main "$@"
