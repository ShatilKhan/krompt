# Architecture Documentation Skill

A universal, installable skill for creating system architecture docs with D2 diagrams, code snippets, and deployment documentation. Works with Cline, Cursor, Inceptor, and any agent that reads markdown rules.

## What's Included

| File | Purpose |
|------|---------|
| `manifest.json` | Skill metadata, triggers, target agents |
| `rules.md` | The core skill rules (icon overlap prevention, doc structure, etc.) |
| `skill.md` | Extended skill documentation with examples |
| `render.sh.template` | Template for the D2→SVG/PNG rendering pipeline |
| `install.sh` | Universal installer with auto-detection |

## Quick Install

### Auto-detect (recommended)
```bash
cd your-project/
bash /path/to/architecture-documentation/install.sh
```

The installer auto-detects your agent environment from project files (`.clinerules`, `.cursorrules`, `.inceptor/`, etc.).

### Manual target selection
```bash
# For Cline (VS Code)
bash install.sh cline

# For Cursor
bash install.sh cursor

# For Inceptor
bash install.sh inceptor

# For any other agent
bash install.sh generic
```

### Remote install (one-liner)
```bash
curl -fsSL https://raw.githubusercontent.com/your-org/architecture-docs-skill/main/install.sh | bash
```

*(Replace with your actual hosted URL after publishing.)*

## How It Works

Once installed, simply say any of these to your agent:

- *"Create architecture docs for this project"*
- *"Document the system architecture"*
- *"Create system diagrams"*
- *"Add deployment docs"*
- *"Document the integration flow"*
- *"Write a system overview"*
- *"Document API contracts"*

The agent will follow the skill's conventions:
1. Create `architecture-docs/` with the standard folder layout
2. Write D2 diagrams with proper icons and `label.near: bottom-center`
3. Extract real code snippets from the codebase
4. Document the three wire contracts
5. Include known-issues tables
6. Generate SVG + PNG renders via `render.sh`

## Key Conventions

### Text/Icon Overlap Prevention
The skill enforces `label.near: bottom-center` on every D2 shape with an icon. This prevents the #1 visual bug in D2 diagrams.

```d2
# ❌ BAD — text overlaps icon
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
}

# ✅ GOOD — label at bottom
api: "API Gateway" {
  icon: https://cdn.simpleicons.org/nginx/009639
  label.near: bottom-center
}
```

### Multi-line Rich Labels
Use D2 markdown blocks for formatted labels:

```d2
llm: |md
  **LLM Driver**
  Claude Haiku 3.5
  via Requesty.AI
|
```

### Accuracy Rules
- Document **actual** providers/models (not defaults)
- Copy **actual** hostnames/ports from docker-compose
- Extract **actual** file paths with `find`/`grep`
- Redact secrets with `***`, never use fake values

## Packaging for Distribution

To create a distributable zip/tarball:

```bash
cd .cline/skills/
zip -r architecture-documentation-v1.0.0.zip architecture-documentation/
# or
tar -czvf architecture-documentation-v1.0.0.tar.gz architecture-documentation/
```

## Manual Install (Without Script)

### Cline / VS Code
Copy `rules.md` into your project root as `.clinerules`.

### Cursor
Copy `rules.md` into your project root as `.cursorrules`.

### Inceptor
Copy the entire `architecture-documentation/` folder into your Inceptor skills directory (e.g., `~/.inceptor/skills/`).

### Generic Agent
Copy `rules.md` into your project root as `AGENTS.md`.

## License

MIT
