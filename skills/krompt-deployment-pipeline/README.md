# Deployment Pipeline Skill

A reusable agent skill that **generates a complete deployment pipeline** for any project — GitHub Actions workflow, Dockerfile, `docker-compose.yml`, Caddyfile, and the migration scaffold for whichever DB tool you use.

Cloud-provider agnostic by default. Supports both **CI-driven** (GitHub Actions) and **git-based auto-deploy** (Vercel/Render/Railway/Fly) paradigms.

---

## What it generates

Tell the skill what you want, and it produces a complete, commit-ready set of files. Examples:

- **EC2 / DO Droplet / Hetzner / any Linux VPS with Docker** — full GitHub Actions workflow (build → push to registry → SCP → SSH → `docker compose up -d`), multi-stage Dockerfile, compose file with Caddy reverse proxy.
- **Vercel + Turso** — `vercel.json`, `/api/*` serverless functions, `lib/db.ts` with `@libsql/client` or `drizzle-orm/libsql`, schema-deploy instructions.
- **DigitalOcean App Platform** — `deploy.template.yaml` + workflow with `digitalocean/app_action`.
- **AWS ECS / Fargate**, **GCP Cloud Run**, **Fly.io**, **Railway**, **Render** — appropriate config + workflow per provider.
- **Generic compose-only** — Dockerfile + compose, no CI.

---

## Installation

### One-liner (auto-detects your agent)

```bash
curl -fsSL https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/krompt-deployment-pipeline/install.sh | bash
```

Add `-s -- --with-templates` to also copy the full templates tree into the agent's skill directory (recommended — the agent reads them directly without re-fetching).

### Supported targets

| Agent        | Auto-detected by                          | Installed to                              |
|--------------|-------------------------------------------|-------------------------------------------|
| Claude Code  | `.claude/` or `~/.claude/skills/`         | `.claude/skills/<name>/SKILL.md`          |
| Cursor       | `.cursor/` or `.cursorrules`              | `.cursor/rules/<name>.mdc`                |
| Cline        | `.clinerules` (file or dir) or `.cline/`  | `.clinerules/<name>.md`                   |
| Windsurf     | `.windsurf/` or `.windsurfrules`          | `.windsurf/rules/<name>.md`               |
| Copilot      | `.github/copilot-instructions.md`         | appended to that file                     |
| Aider        | `.aider.conf.yml` or `CONVENTIONS.md`     | appended to `CONVENTIONS.md`              |
| Generic      | (fallback)                                | appended to `AGENTS.md`                   |

### Force a specific target

```bash
curl -fsSL <url>/install.sh | bash -s -- claude-code --scope user --with-templates
curl -fsSL <url>/install.sh | bash -s -- cursor --with-templates
curl -fsSL <url>/install.sh | bash -s -- generic --force
```

Re-runs are idempotent (`--force` to overwrite). Block markers: `<!-- krompt:krompt-deployment-pipeline:start/end -->`.

---

## How to use it

Once installed, ask your agent something like:

> "Use the deployment-pipeline skill. Generate a pipeline for a Bun backend named `widget-api` on port `4000`, deploying via `ssh-host-docker-caddy` to a Hetzner box, build mode `source-to-host`, secrets via `heredoc`, deploy branch `main`, Drizzle migrations against Supabase."

You'll get back:
- `.github/workflows/deploy.yml`
- `Dockerfile`
- `docker-compose.yml`
- `Caddyfile`
- `drizzle.config.ts` + `src/db/migrate.ts` + four package scripts
- A list of secrets to add (`DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DATABASE_URL`, etc.)
- One-time host setup commands

For Vercel + Turso:

> "Use the deployment-pipeline skill. Set up a Vercel serverless project with Turso, /api routes for webhook and dashboard, plus a static React frontend."

You'll get `vercel.json`, `/api/*.ts` handlers, `lib/db.ts`, and `vercel env add` / `turso db create` commands.

---

## Decision axes the skill walks you through

1. Language / runtime
2. Deployment paradigm (CI-driven vs git-based auto-deploy)
3. Deployment target (9 options)
4. Build/registry model (`registry-first` vs `source-to-host`, for the SSH-host mode)
5. Secret-injection style (`echo-loop` / `heredoc` / `branch-env-files`)
6. CI runner (asked, never assumed)
7. Deploy branches
8. Migration setup (auto-detected; otherwise asked) — 12+ tools supported, 6 with first-class scaffolds
9. Healthcheck on/off

---

## What the skill does NOT do

- Provision infrastructure (Terraform / Pulumi / CDK — different layer).
- Manage secrets beyond GitHub Secrets / Vercel env / Turso CLI (no Vault, no AWS Secrets Manager integration).
- Database backups, blue/green orchestration, or multi-region failover.
- Kubernetes / Helm / Nomad.

---

## License

MIT.
