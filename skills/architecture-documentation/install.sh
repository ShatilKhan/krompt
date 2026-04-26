#!/usr/bin/env bash
# Architecture Documentation Skill — Universal Installer
# Supports: Cline, Cursor, Inceptor, Generic (AGENTS.md)
# Works when run locally OR piped: curl -fsSL ... | bash

set -eo pipefail

SKILL_NAME="architecture-documentation"
SKILL_VERSION="1.0.0"

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
        echo "local"
    else
        echo "piped"
    fi
}

# Get the directory containing this script (local mode only)
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

# Emit rules.md content (embedded for piped mode, read from disk for local mode)
emit_rules() {
    local mode="$1"
    if [[ "$mode" == "local" ]]; then
        local script_dir
        script_dir=$(get_script_dir)
        if [[ -f "$script_dir/rules.md" ]]; then
            cat "$script_dir/rules.md"
            return
        fi
    fi

    # Embedded rules.md content (fallback for piped mode)
    cat <<'RULES_EOF'
# Architecture Documentation Skill

When asked to create, update, or refine architecture documentation for any project, follow these patterns derived from best practices for technical documentation.

## 1. Document Structure

Create a top-level `architecture-docs/` folder with this standard layout:

```
architecture-docs/
├── 01-overview.md              # System context, request lifecycle, wire contracts
├── 02-integration.md           # Module/component maps, API contracts, flow diagrams
├── 03-frontend-flow.md         # UI rendering pipeline, component registry, state management
├── 04-deployment.md            # Docker Compose, environment matrix, topology diagrams
├── README.md                   # How to render diagrams, toolchain, source of truth
└── diagrams/
    ├── render.sh               # Single command to regenerate all outputs
    ├── 01-context.d2
    ├── 02-components.d2
    ├── 03-sequence.d2
    ├── 04-ui-flow.d2
    ├── 05-deployment.d2
    └── out/                    # Committed SVG + PNG renders
```

Adapt the numbered docs to the project's actual concerns.

## 2. Diagram Authoring (D2)

Use **[D2](https://d2lang.com)** (`*.d2`) as the source of truth for all diagrams.

### Icon Sources
- **Simple Icons**: `https://cdn.simpleicons.org/{name}/{color}`
- **Terrastruct**: `https://icons.terrastruct.com/{category}%2F{file}.svg`
- **Lobe Icons**: `https://cdn.jsdelivr.net/gh/lobehub/lobe-icons/packages/static-svg/icons/{name}.svg`

### CRITICAL: Prevent Text/Icon Overlap

Any shape with both an `icon:` and a text label MUST include `label.near: bottom-center`:

```d2
# BAD
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
}

# GOOD
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
  label.near: bottom-center
}
```

### Multi-line Labels

Use `\n` for simple breaks, `|md` blocks for rich formatting:
```d2
llm: |md
  **LLM Driver**
  Claude Haiku 3.5
  via Requesty.AI
|
```

### Shape Types
- `shape: person` for users
- `shape: cylinder` for databases/storage
- Default rectangle for services

## 3. Markdown Doc Patterns

### Embed Real Code Snippets

Extract actual snippets with file paths and line numbers:
```ts
// api/src/modules/mcp/mcp.controller.ts:31–60
@Get('list_tools')
@UseGuards(JwtAuthGuard)
listTools(...) { ... }
```

### Three Wire Contracts
1. Frontend → Backend (API contract)
2. Backend → External Service (integration contract)
3. External Service → Frontend (response envelope)

### Known Issues Table
```markdown
| # | Concern | Location |
|---|---------|----------|
| 1 | `arguments: any` — no schema validation | `dto/call-tool.dto.ts` |
```

### Request Lifecycle
Document as a numbered list referencing actual file/function names.

## 4. Rendering Pipeline

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out
for src in *.d2; do
    name="${src%.d2}"
    d2 "$src" "out/${name}.svg"
    d2 "$src" "out/${name}.png"
done
```

## 5. Accuracy Rules

- **Actual providers/models**: Document truth, note convention differences
- **Actual hostnames/ports**: Copy from docker-compose files
- **Actual file paths**: Use `find`/`grep`, never guess
- **No placeholders**: Redact secrets with `***`

## 6. Workflow Checklist

- [ ] Create `architecture-docs/` with standard structure
- [ ] Write D2 diagrams with `label.near: bottom-center`
- [ ] Extract real code snippets with paths and line numbers
- [ ] Document the three wire contracts
- [ ] Document the happy-path request lifecycle
- [ ] Include known-issues table
- [ ] Write `render.sh` and generate SVG + PNG
- [ ] Update README with rendering instructions
- [ ] Verify no text/icon overlaps in rendered outputs
- [ ] Verify provider/model names are accurate
RULES_EOF
}

# Install rules into target file
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
            emit_rules "$mode"
            echo "# --- End Architecture Documentation Skill ---"
        } >> "$dest"
    else
        emit_rules "$mode" > "$dest"
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
    local script_dir
    script_dir=$(get_script_dir)
    local files="README.md install.sh manifest.json render.sh.template rules.md skill.md"

    for f in $files; do
        if [[ "$mode" == "local" && -n "$script_dir" && -f "$script_dir/$f" ]]; then
            cp "$script_dir/$f" "$dest/$SKILL_NAME/$f"
        else
            fetch "https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/${SKILL_NAME}/$f" > "$dest/$SKILL_NAME/$f"
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
