# Architecture Documentation Skill

**Trigger phrases:** "create architecture docs", "document the architecture", "create system diagrams", "update architecture documentation", "add deployment docs", "document the integration flow"

**Applies to:** Any software project needing technical architecture documentation, deployment runbooks, or system-design write-ups.

---

## 0. Configuration & Overrides

Before generating, check whether the user has specified any overrides:

| Parameter | Default | Override example |
|-----------|---------|------------------|
| **Layout engine** | `elk` | "Use TALA for the diagrams" -> `--layout=tala` or `D2_LAYOUT=tala` |
| **Docs to generate** | All (auto-detected) | "Just the overview and db schema" -> generate only `01-overview.md` + `03-db-schema.md` |
| **Diagrams to generate** | All (auto-detected) | "Only the context and components diagrams" -> generate only those `.d2` files |
| **Output size** | 800x418 px | "Make it 1200x630" -> `TARGET_W=1200 TARGET_H=630` |

**Layout engine quick-reference:**
- **ELK** (default) -- Free, actively maintained, clean orthogonal routes, native container-to-container routing, sql_table connections point to exact rows. Best for layered architecture and microservices.
- **TALA** (opt-in: `D2_LAYOUT=tala`) -- Proprietary, designed for software architecture. Per-container direction control, fixed positioning (`top`/`left`), `near` with objects. Produces whiteboard-quality diagrams. Install separately from https://github.com/terrastruct/tala.
- **Dagre** (fallback) -- D2's built-in default, fast but unmaintained since 2018.

If no override is given, auto-detect the project structure and generate the appropriate set of docs/diagrams using the defaults below.

---

## 1. Output Structure

Create a top-level `architecture-docs/` folder with this standard layout (adapt numbered docs to project concerns):

```
architecture-docs/
├── 01-overview.md              # System context, request lifecycle, wire contracts
├── 02-integration.md           # Module/component maps, API contracts, flow diagrams
├── 03-db-schema.md             # Database schema / ERD (before frontend)
├── 04-frontend-flow.md         # UI rendering pipeline, component registry, state management
├── 05-deployment.md            # Docker Compose, environment matrix, topology diagrams
├── README.md                   # How to render diagrams, toolchain, source of truth
└── diagrams/
    ├── render.sh               # Single command to regenerate all outputs
    ├── 01-context.d2           # System context diagram
    ├── 02-components.d2        # System architecture (services, gateways, data stores)
    ├── 03-sequence.d2          # Request sequence diagrams
    ├── 04-db-schema.d2         # Database ERD (sql_table shapes)
    ├── 05-ui-flow.d2           # Frontend UI flow / state management
    ├── 06-ui-components.d2     # Frontend component hierarchy (grid layout)
    ├── 07-deployment.d2        # Deployment topology
    └── out/                    # Committed SVG + PNG renders
```

Adapt the numbered docs to the project's actual concerns (e.g., `02-mcp-integration.md`, `05-generative-ui.md`). Skip docs/diagrams that aren't relevant (e.g., skip `06-ui-components.d2` for a backend-only project).

**Detection logic:**
- `package.json` + `src/components` -> frontend exists -> include `04-frontend-flow.md` + `06-ui-components.d2`
- `docker-compose.yml` / `Dockerfile` / multiple services -> services exist -> include `02-components.d2`
- Prisma schema / TypeORM entities / SQL migration files -> database exists -> include `03-db-schema.md` + `04-db-schema.d2`

---

## 2. Diagram Authoring (D2)

Use **[D2](https://d2lang.com)** (`*.d2`) as the source of truth for all diagrams. D2 is a single Go binary with no system dependencies.

### Layout Engine

```bash
# Default (recommended): ELK
d2 --layout=elk --pad 20 diagram.d2 out/diagram.svg

# Opt-in: TALA (better software-architecture layouts, per-container direction)
D2_LAYOUT=tala d2 --pad 20 diagram.d2 out/diagram.svg
```

When generating `render.sh`, include the `D2_LAYOUT` env var so users can override:
```bash
LAYOUT="${D2_LAYOUT:-elk}"
d2 --layout="$LAYOUT" --pad 20 "$src" "out/${name}.svg"
```

### Icon Sources (use HTTPS URLs, fetched at render time)

Resolution order (Simple Icons lags on new AI startups -- the top cause of missing logos):

1. **AI / LLM brands -> Lobe Icons**: `https://cdn.jsdelivr.net/npm/@lobehub/icons-static-svg@latest/icons/{name}.svg`
   - Themed PNG fallback: `https://cdn.jsdelivr.net/npm/@lobehub/icons-static-png@latest/{light|dark}/{name}.png`
   - Lowercase names, optional `-color`/`-text`: `anthropic`, `claude-color`, `claudecode-color`, `openai`, `gemini-color`, `mistral-color`, `groq`, `perplexity-color`, `ollama`, `deepseek-color`, `qwen-color`, `grok`, `xai`. Browse: <https://icons.lobehub.com>
2. **Modern dev/SaaS -> SVGL**: `https://api.svgl.app/svg/{name}.svg`
3. **Catch-all -> Iconify**: `https://api.iconify.design/{prefix}:{name}.svg` (`logos:` color, `simple-icons:` mono)
4. **OSS/lang/framework -> Simple Icons**: `https://cdn.simpleicons.org/{name}/{color}` (e.g., `/react/61DAFB`, `/nestjs/E0234E`)
5. **Cloud/infra -> Terrastruct**: `https://icons.terrastruct.com/{category}%2F{file}.svg`

If a logo is missing, walk the chain (Lobe -> SVGL -> Iconify -> Simple Icons) rather than inventing a URL; fall back to a plain labeled shape only as a last resort, and confirm it renders (a 404 shows as an empty box).

### Generic Concept Icon Map

For components that don't have a brand logo (generic services, concepts, infrastructure), use Iconify Material Design Icons (`mdi:` prefix) which are reliable, universally recognized, and work in D2:

```
Generic Database   -> https://api.iconify.design/mdi:database.svg
Generic Server     -> https://api.iconify.design/mdi:server.svg
Generic Cloud      -> https://api.iconify.design/mdi:cloud.svg
Generic Storage    -> https://api.iconify.design/mdi:storage.svg
Generic API        -> https://api.iconify.design/material-symbols:api.svg
API Gateway        -> https://api.iconify.design/hugeicons:api-gateway.svg
Message Queue      -> https://api.iconify.design/carbon:message-queue.svg
Cache              -> https://api.iconify.design/octicon:cache-16.svg
File/Blob Storage  -> https://api.iconify.design/mdi:file.svg
Notification       -> https://api.iconify.design/mdi:bell.svg
Authentication     -> https://api.iconify.design/mdi:account-lock.svg
User / Person      -> https://api.iconify.design/mdi:account.svg
Network / LB       -> https://api.iconify.design/mdi:wan.svg
Container / Pod    -> https://api.iconify.design/mdi:docker.svg
Code / Function    -> https://api.iconify.design/mdi:code-json.svg
Email              -> https://api.iconify.design/mdi:email.svg
Clock / Cron       -> https://api.iconify.design/mdi:clock.svg
Credit Card / Pay  -> https://api.iconify.design/mdi:credit-card.svg
Search             -> https://api.iconify.design/mdi:file-search.svg
Logs / Monitoring  -> https://api.iconify.design/mdi:chart-box.svg
```

**Rule:** EVERY node in every diagram MUST have an icon. Use brand logos where available, fall back to this generic map otherwise. A diagram with no icons looks incomplete.

### CRITICAL: Prevent Text/Icon Overlap

Any shape that has both an `icon:` and a text label MUST include `label.near: bottom-center`. D2's default places the label at the top-center, which overlaps with the icon.

```d2
# BAD -- text overlaps icon
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
}

# GOOD -- label at bottom, icon at top
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
- `shape: sql_table` for database table schemas (see DB Schema pattern below)
- Default `shape: rectangle` for services, modules, containers

### Components Architecture Visualization

The key diagram is `02-components.d2` (system architecture). The visualization strategy depends on the project type. Below are three patterns -- pick the one that matches the project.

---

#### Pattern A: Frontend-Only (React/Vue/Angular without backend services)

**When:** Project has only UI components, no detectable backend services.

**Strategy:** Group components by feature/domain using containers, arrange horizontally (`direction: right`).

```d2
direction: right

layout_comps: "Layout" {
  header: "Header" {
    icon: https://api.iconify.design/mdi:page-layout-header.svg
    label.near: bottom-center
  }
  sidebar: "Sidebar" {
    icon: https://api.iconify.design/mdi:view-sidebar.svg
    label.near: bottom-center
  }
  footer: "Footer" {
    icon: https://api.iconify.design/mdi:page-layout-footer.svg
    label.near: bottom-center
  }
}

form_comps: "Forms" {
  input: "TextInput" {
    icon: https://api.iconify.design/mdi:form-textbox.svg
    label.near: bottom-center
  }
  select: "Select" {
    icon: https://api.iconify.design/mdi:form-select.svg
    label.near: bottom-center
  }
}
```

**When to break out:** If there are >15 components, split into multiple diagrams by feature domain.

---

#### Pattern B: Microservice / Backend-Heavy (default when services detected)

**When:** `docker-compose.yml`, `Dockerfile`s, multiple service directories, or API route files exist.

**Strategy:** Use **layered containers** where each container represents an architecture layer. Arrange left-to-right with `direction: right` for the landscape format.

```d2
direction: right

clients: "Clients" {
  web: "Web App" {
    icon: https://cdn.simpleicons.org/react/61DAFB
    label.near: bottom-center
  }
  mobile: "Mobile App" {
    icon: https://api.iconify.design/mdi:cellphone.svg
    label.near: bottom-center
  }
}

gateway: "Gateway" {
  api_gw: "API Gateway" {
    icon: https://api.iconify.design/hugeicons:api-gateway.svg
    label.near: bottom-center
  }
}

services: "Services" {
  auth: "Auth" {
    icon: https://api.iconify.design/mdi:account-lock.svg
    label.near: bottom-center
  }
  payment: "Payment" {
    icon: https://api.iconify.design/mdi:credit-card.svg
    label.near: bottom-center
  }
  notify: "Notification" {
    icon: https://api.iconify.design/mdi:bell.svg
    label.near: bottom-center
  }
}

data: "Data Stores" {
  postgres: "PostgreSQL" { shape: cylinder }
  redis: "Redis Cache" { shape: cylinder }
}

ext: "External" {
  email_svc: "Email" {
    icon: https://api.iconify.design/mdi:email.svg
    label.near: bottom-center
  }
}

# Connections across layers
clients -> api_gw: "HTTPS"
api_gw -> services: "Internal"
services -> data: "SQL/Redis"
services -> email_svc: "SMTP"
```

**Layer order (left to right):** Clients -> Gateway -> Services -> Data Stores -> External

**Rules for this pattern:**
- Keep each layer to <=6 nodes. If a layer has more, split into sub-containers (e.g., `billing_services`, `user_services`).
- Each node gets an icon -- brand logo OR generic from the map above.
- Data stores always use `shape: cylinder`.
- Connection labels are optional but helpful for protocol clarity.
- If using TALA (`D2_LAYOUT=tala`), you can set `direction: up` or `direction: down` per container for vertical stacking inside a layer.

---

#### Pattern C: Hybrid (Frontend + Backend Services)

**When:** Project has both UI components AND backend services.

**Strategy:** Frontend components stay in `06-ui-components.d2` (see below). `02-components.d2` shows the high-level architecture (Pattern B). The frontend appears as a single `"Web App"` node under `Clients` in the system diagram, with its internal complexity deferred to the UI-specific diagram.

---

### Database Schema Diagram (`04-db-schema.d2`)

Use D2's native `sql_table` shape for entity-relationship diagrams.

```d2
direction: right

# Each database gets a container with an icon
primary_db: "Primary Database" {
  icon: https://api.iconify.design/mdi:database.svg

  users: {
    shape: sql_table
    id: int { constraint: primary_key }
    email: varchar(255) { constraint: unique }
    name: varchar(100)
    created_at: timestamp
  }

  orders: {
    shape: sql_table
    id: int { constraint: primary_key }
    user_id: int { constraint: foreign_key }
    total: decimal(10,2)
    status: varchar(50)
    created_at: timestamp
  }

  # Foreign key connection
  users.id -> orders.user_id
}

cache: "Redis Cache" {
  icon: https://api.iconify.design/octicon:cache-16.svg
  shape: cylinder
}
```

**Rules:**
- Extract actual schema from code (Prisma, TypeORM, SQL migrations, Knex, etc.) -- never invent columns.
- Max 4-6 tables per diagram for readability at 800x418. Split large schemas into domain sub-diagrams.
- Each database container gets an icon (generic `mdi:database` or brand-specific like `simple-icons:postgresql`).
- FK connections point to exact rows when using ELK or TALA layout engines.
- D2 auto-shortens constraints: `primary_key` -> `PK`, `foreign_key` -> `FK`, `unique` -> `UNQ`.
- Use `shape: cylinder` for non-relational data stores (Redis, S3, etc.) instead of `sql_table`.

---

### Frontend UI Components Diagram (`06-ui-components.d2`)

Referenced from `04-frontend-flow.md` as a secondary diagram alongside the UI flow.

Use D2's **grid layout** for evenly-spaced component catalogs:

```d2
grid-rows: 3
grid-columns: 4
grid-gap: 15

layout: "Layout Components" {
  icon: https://api.iconify.design/mdi:view-dashboard.svg
  header: "Header" {
    icon: https://api.iconify.design/mdi:page-layout-header.svg
    label.near: bottom-center
  }
  sidebar: "Sidebar" {
    icon: https://api.iconify.design/mdi:view-sidebar.svg
    label.near: bottom-center
  }
  footer: "Footer" {
    icon: https://api.iconify.design/mdi:page-layout-footer.svg
    label.near: bottom-center
  }
}

forms: "Form Components" {
  icon: https://api.iconify.design/mdi:form-textbox.svg
  text_input: "TextInput" {
    icon: https://api.iconify.design/mdi:form-textbox.svg
    label.near: bottom-center
  }
  select: "Select" {
    icon: https://api.iconify.design/mdi:form-select.svg
    label.near: bottom-center
  }
  date: "DatePicker" {
    icon: https://api.iconify.design/mdi:calendar.svg
    label.near: bottom-center
  }
}

feedback: "Feedback Components" {
  icon: https://api.iconify.design/mdi:bell.svg
  toast: "Toast" {
    icon: https://api.iconify.design/mdi:message.svg
    label.near: bottom-center
  }
  modal: "Modal" {
    icon: https://api.iconify.design/mdi:window-maximize.svg
    label.near: bottom-center
  }
  spinner: "Spinner" {
    icon: https://api.iconify.design/mdi:loading.svg
    label.near: bottom-center
  }
}
```

**Rules:**
- Scan `src/components` (or equivalent) for actual component files.
- Group by feature/category into containers.
- Use `grid-rows` and `grid-columns` for even distribution in the landscape format.
- EVERY component gets an icon -- use the generic icon map for non-branded UI concepts.
- If >20 components, split into multiple grid diagrams by domain.

---

## 3. Markdown Doc Patterns

### Embed Real Code Snippets

Never write pseudo-code. Extract actual snippets from the codebase with:
- Exact file path
- Line number ranges
- Syntax-highlighted fenced code blocks

Example:
```markdown
```ts
// api/src/modules/mcp/mcp.controller.ts:31-60
@Get('list_tools')
@UseGuards(JwtAuthGuard)
listTools(@Headers('organization') organization: number) {
    ...
}
```
```

### Three Wire Contracts Pattern

For system overviews, always document the three primary wire contracts:
1. Frontend -> Backend (API contract)
2. Backend -> External Service (integration contract)
3. External Service -> Frontend (response envelope contract)

### Known Issues Table

End each deep-dive doc with a markdown table of known issues:
```markdown
| # | Concern | Location |
|---|---------|----------|
| 1 | `arguments: any` -- no schema validation | `dto/call-tool.dto.ts` |
| 2 | 51-case switch -- two sources of truth | `mcp.service.ts:51-335` |
```

### Request Lifecycle

Document the happy-path request lifecycle as a numbered list. Each step should reference actual file/function names.

## 4. Rendering Pipeline

Render diagrams to **800x418 px PNG** by default -- the cover-image spec used by
Dev.to, Hashnode, and Medium (1.91:1, ~Open Graph aspect). This keeps embeds
crisp inline AND as social cards without per-platform tweaks. Always emit both
`.svg` (source of truth) and `.png` (sized for blog blocks).

Provide a `render.sh` in `diagrams/`:

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
mkdir -p out

TARGET_W="${TARGET_W:-800}"
TARGET_H="${TARGET_H:-418}"
PAD_ONLY="${PAD_ONLY:-1}"   # 1 = letterbox (preserve aspect), 0 = center-crop
LAYOUT="${D2_LAYOUT:-elk}"   # default ELK, override via D2_LAYOUT=tala

for src in *.d2; do
    name="${src%.d2}"
    echo ">>> $name (layout=$LAYOUT)"
    d2 --layout="$LAYOUT" --pad 20 "$src" "out/${name}.svg"
    d2 --layout="$LAYOUT" --pad 20 "$src" "out/${name}.raw.png"
    if [[ "$PAD_ONLY" == "1" ]]; then
        magick "out/${name}.raw.png" -resize "${TARGET_W}x${TARGET_H}"             -background white -gravity center             -extent "${TARGET_W}x${TARGET_H}" "out/${name}.png"
    else
        magick "out/${name}.raw.png" -resize "${TARGET_W}x${TARGET_H}^"             -gravity center -extent "${TARGET_W}x${TARGET_H}" "out/${name}.png"
    fi
    rm -f "out/${name}.raw.png"
done

echo "Done. Outputs (${TARGET_W}x${TARGET_H}) in ./out/"
```

**Authoring tips for 800x418:**
- Aim for **horizontal/landscape** D2 layouts (`direction: right`) -- vertical stacks letterbox poorly into a 1.91:1 frame.
- Keep node labels short; long text shrinks on downscale.
- Run `render.sh` and visually verify every PNG -- letterboxing should leave only thin top/bottom bands, not large empty regions. If it does, redesign the diagram horizontally.
- Requires `d2` and ImageMagick (`magick`/`convert`) on PATH. `rsvg-convert` works too but cannot letterbox.

Embed PNGs in blog posts (correct size for blocks):
```markdown
![System context](./diagrams/out/01-context.png)
```

Embed SVGs in repo docs (crisp at any zoom, GitHub/VS Code compatible -- **preferred for readability**):
```markdown
![System context](./diagrams/out/01-context.svg)
```

## 5. Accuracy Rules

- **Actual providers/models**: If the project uses Requesty.AI + Claude instead of OpenAI + GPT-4, document the truth. Note when the integration follows another vendor's convention (e.g., "OpenAI-style tool-calling").
- **Actual hostnames/ports**: Copy from docker-compose files, not memory.
- **Actual file paths**: Use `find` or `grep` to locate real files, don't guess.
- **No placeholders**: Redact secrets with `***`, never use fake values.
- **Actual schema**: Extract real columns, types, and constraints from Prisma/TypeORM/SQL files -- never invent tables.

## 6. README Template

```markdown
# {Project} -- Architecture Docs

Diagrams are authored in **[D2](https://d2lang.com)** and pre-rendered to SVG + PNG.

## Contents

| File | What it covers |
|------|----------------|
| [`01-overview.md`](./01-overview.md) | System context + request lifecycle |
| [`02-integration.md`](./02-integration.md) | Module/component maps + API contracts |
| [`03-db-schema.md`](./03-db-schema.md) | Database schema / ERD |
| [`04-frontend-flow.md`](./04-frontend-flow.md) | UI pipeline + component tree |
| [`05-deployment.md`](./05-deployment.md) | Deployment topology |

**Layout engine:** ELK (override via `D2_LAYOUT=tala`)

## Re-rendering

```bash
curl -fsSL https://d2lang.com/install.sh | sh -s --
export PATH=$HOME/.local/bin:$PATH
./architecture-docs/diagrams/render.sh
```

To use TALA instead:
```bash
D2_LAYOUT=tala ./architecture-docs/diagrams/render.sh
```
```

## 7. Workflow Checklist

When creating or updating architecture docs:

- [ ] Check user overrides (layout engine, doc selection, diagram selection)
- [ ] Scan project to auto-detect: frontend? backend services? database?
- [ ] Create `architecture-docs/` folder with appropriate docs/diagrams
- [ ] Write `02-components.d2` using the correct pattern (A/B/C based on project)
- [ ] Write `04-db-schema.d2` using `sql_table` shapes (when DB detected)
- [ ] Write `06-ui-components.d2` using grid layout (when frontend detected)
- [ ] Apply icons to ALL shapes -- brand logos OR generic concept icons
- [ ] Apply `label.near: bottom-center` to all non-container shapes with icons
- [ ] Extract real code snippets with file paths and line numbers
- [ ] Document the three wire contracts
- [ ] Document the happy-path request lifecycle
- [ ] Include a known-issues table
- [ ] Write `render.sh` (with `--layout=elk` default) and generate SVG + PNG outputs
- [ ] Update README with rendering instructions
- [ ] Verify no text/icon overlaps in rendered outputs
- [ ] Verify all provider/model names are accurate to the codebase
- [ ] Verify real database schema types and constraints
