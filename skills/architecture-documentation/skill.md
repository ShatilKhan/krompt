# Architecture Documentation Skill

**Trigger phrases:** "create architecture docs", "document the architecture", "create system diagrams", "update architecture documentation", "add deployment docs", "document the integration flow"

**Applies to:** Any software project needing technical architecture documentation, deployment runbooks, or system-design write-ups.

---

## 1. Output Structure

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

Adapt the numbered docs to the project's actual concerns (e.g., `02-mcp-integration.md`, `03-generative-ui.md`).

## 2. Diagram Authoring (D2)

Use **[D2](https://d2lang.com)** (`*.d2`) as the source of truth for all diagrams. D2 is a single Go binary with no system dependencies.

### Icon Sources (use HTTPS URLs, fetched at render time)
- **Simple Icons**: `https://cdn.simpleicons.org/{name}/{color}` (e.g., `/react/61DAFB`, `/nestjs/E0234E`)
- **Terrastruct**: `https://icons.terrastruct.com/{category}%2F{file}.svg`
- **Lobe Icons**: `https://cdn.jsdelivr.net/gh/lobehub/lobe-icons/packages/static-svg/icons/{name}.svg`

### CRITICAL: Prevent Text/Icon Overlap

Any shape that has both an `icon:` and a text label MUST include `label.near: bottom-center`. D2's default places the label at the top-center, which overlaps with the icon.

```d2
# BAD — text overlaps icon
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
}

# GOOD — label at bottom, icon at top
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
  label.near: bottom-center
}
```

Apply this to ALL non-container shapes with icons. Container shapes (subgraphs) are usually wide enough that the header text and icon don't collide, but add it if they do.

### Multi-line Labels

Use literal `\n` inside double-quoted strings for simple line breaks:
```d2
service: "Service Name\nSecond line"
```

Use D2 markdown blocks (`|md`) for rich formatting (bold, lists, paragraphs):
```d2
llm: |md
  **LLM Driver**
  Claude Haiku 3.5
  via Requesty.AI
|
```

### Shape Types
- `shape: person` for users/humans
- `shape: cylinder` for databases, caches, storage
- Default `shape: rectangle` for services, modules, containers

## 3. Markdown Doc Patterns

### Embed Real Code Snippets

Never write pseudo-code. Extract actual snippets from the codebase with:
- Exact file path
- Line number ranges
- Syntax-highlighted fenced code blocks

Example:
```markdown
```ts
// api/src/modules/mcp/mcp.controller.ts:31–60
@Get('list_tools')
@UseGuards(JwtAuthGuard)
listTools(@Headers('organization') organization: number) {
    ...
}
```
```

### Three Wire Contracts Pattern

For system overviews, always document the three primary wire contracts:
1. Frontend → Backend (API contract)
2. Backend → External Service (integration contract)
3. External Service → Frontend (response envelope contract)

### Known Issues Table

End each deep-dive doc with a markdown table of known issues:
```markdown
| # | Concern | Location |
|---|---------|----------|
| 1 | `arguments: any` — no schema validation | `dto/call-tool.dto.ts` |
| 2 | 51-case switch — two sources of truth | `mcp.service.ts:51–335` |
```

### Request Lifecycle

Document the happy-path request lifecycle as a numbered list. Each step should reference actual file/function names.

## 4. Rendering Pipeline

Provide a `render.sh` in `diagrams/`:

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
mkdir -p out

for src in *.d2; do
    name="${src%.d2}"
    echo ">>> $name"
    d2 "$src" "out/${name}.svg"
    d2 "$src" "out/${name}.png"
done

echo "Done. Outputs in ./out/"
```

Embed SVGs in markdown (GitHub/VS Code compatible):
```markdown
![System context](./diagrams/out/01-context.svg)
```

## 5. Accuracy Rules

- **Actual providers/models**: If the project uses Requesty.AI + Claude instead of OpenAI + GPT-4, document the truth. Note when the integration follows another vendor's convention (e.g., "OpenAI-style tool-calling").
- **Actual hostnames/ports**: Copy from docker-compose files, not memory.
- **Actual file paths**: Use `find` or `grep` to locate real files, don't guess.
- **No placeholders**: Redact secrets with `***`, never use fake values.

## 6. README Template

```markdown
# {Project} — Architecture Docs

Diagrams are authored in **[D2](https://d2lang.com)** and pre-rendered to SVG + PNG.

## Contents

| File | What it covers |
|------|----------------|
| [`01-overview.md`](./01-overview.md) | System context + request lifecycle |
| ... | ... |

## Re-rendering

```bash
curl -fsSL https://d2lang.com/install.sh | sh -s --
export PATH=$HOME/.local/bin:$PATH
./architecture-docs/diagrams/render.sh
```
```

## 7. Workflow Checklist

When creating or updating architecture docs:

- [ ] Create `architecture-docs/` folder with standard structure
- [ ] Write D2 diagrams with proper icons and `label.near: bottom-center`
- [ ] Extract real code snippets with file paths and line numbers
- [ ] Document the three wire contracts
- [ ] Document the happy-path request lifecycle
- [ ] Include a known-issues table
- [ ] Write `render.sh` and generate SVG + PNG outputs
- [ ] Update README with rendering instructions
- [ ] Verify no text/icon overlaps in rendered outputs
- [ ] Verify all provider/model names are accurate to the codebase
