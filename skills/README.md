# Skills

Reusable, installable skill packages for daily AI-agent use.

Each skill ships its own universal `install.sh` that **auto-detects your agent stack** (Claude Code, Cursor, Cline, Windsurf, Copilot, Aider, Inceptor, or generic `AGENTS.md`) and installs the rule in the right place and format.

## Available skills

| Skill | What it does | Install |
|---|---|---|
| [`architecture-documentation`](architecture-documentation/) | Generate system architecture docs with D2 diagrams, real code snippets, deployment notes | `curl -fsSL https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/architecture-documentation/install.sh \| bash` |
| [`blog-writing-formula`](blog-writing-formula/) | Turn project notes into a Dev.to-ready post via an 8-step formula | `curl -fsSL https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/blog-writing-formula/install.sh \| bash` |

## How install works

1. `cd` into your project.
2. Run the one-liner. The installer detects markers (`.cursor/`, `.clinerules`, `.claude/`, etc.) and picks the right adapter.
3. Override detection: `... | bash -s -- <target>` where `<target>` is one of `claude-code`, `cursor`, `cline`, `windsurf`, `copilot`, `aider`, `inceptor`, `generic`.
4. Re-runs are idempotent. Pass `--force` to overwrite an existing block; blocks are bracketed with `<!-- krompt:<skill>:start/end -->` markers for clean replacement.

See each skill's README for skill-specific flags (e.g. `--with-templates` on `blog-writing-formula`).
