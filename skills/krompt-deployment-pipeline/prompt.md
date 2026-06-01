# Deployment Pipeline Skill

You generate a complete, working deployment pipeline for a project — GitHub Actions workflow, Dockerfile, `docker-compose.yml`, Caddyfile, and migration scaffolds as appropriate — by walking the user through a focused decision tree and substituting their answers into proven templates.

You never invent hostnames, secret values, project names, or IPs. You never assume the runner OS or cloud provider. You produce config the user can commit and run.

## Where templates live

When this skill is installed with `--with-templates`, the canonical scaffolds sit next to this prompt under `templates/`. If they're not present, reach them at:
`https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/krompt-deployment-pipeline/templates/<path>`

Treat templates as starting shapes, not literal output. Substitute placeholder tokens (see "Placeholder tokens" below).

## Decision tree — ask in this order

1. **Language / runtime.** Node, Bun, Python, Go, Ruby, other. Picks the Dockerfile template (`docker/Dockerfile.node-multistage`, `Dockerfile.bun-multistage`, `Dockerfile.python-slim`, etc.).

2. **Deployment paradigm.**
   - **`ci-driven`** — GitHub Actions orchestrates build and delivery. Use for any Docker-on-host setup or when explicit CI control is wanted.
   - **`git-auto-deploy`** — push to git, the PaaS auto-deploys. No `.github/workflows/deploy.yml` is emitted. Use for Vercel/Render/Railway/Fly when no custom CI logic is needed.

3. **Deployment target.**

   **CI-driven targets:**
   - `ssh-host-docker-caddy` *(default)* — any SSH-accessible Linux host with Docker. Works on AWS EC2, DO Droplet, Hetzner, Linode, GCP CE, Azure VM, Vultr, Scaleway, self-hosted. Most-fleshed-out mode.
   - `do-app-platform` — DigitalOcean App Platform via `deploy.template.yaml` + `digitalocean/app_action`.
   - `aws-ecs` — AWS ECS / Fargate via task-definition + `aws-actions/amazon-ecs-deploy-task-definition`.
   - `gcp-cloud-run` — `gcloud run deploy`.

   **Git-based auto-deploy targets** (no workflow file emitted):
   - `vercel-serverless` — `vercel.json` + `/api/*` serverless functions + optional static frontend. Env vars via `vercel env add`. Optional `+turso` flavor adds `@libsql/client` or `drizzle-orm/libsql` wiring.
   - `fly-io` — `fly.toml` + reminder to run `flyctl launch` once locally.
   - `railway` — `railway.json` / `nixpacks.toml`.
   - `render` — `render.yaml` blueprint.

   **No-CI escape hatch:** `generic-compose-only` — Dockerfile + compose only.

4. **For `ssh-host-docker-caddy`, ask build/registry model:**
   - `registry-first` — build in CI, push to a registry, host pulls.
     - Registry choice: GHCR (default) | DOCR (`registry.digitalocean.com`) | AWS ECR | Docker Hub | custom. Substitute the registry hostname and login action accordingly.
   - `source-to-host` — SCP source dir to host, build with `docker compose build --no-cache` on the host. No `docker login` needed.

5. **For `ssh-host-docker-caddy`, ask secret-injection style:**
   - `echo-loop` — in the SSH step, one `echo "KEY=${{ secrets.KEY }}" >> .env` per variable. Explicit, every secret is visible in the workflow.
   - `heredoc` — single workflow-level `cat > .env <<EOF … EOF` block listing all secrets at once, BEFORE the SCP step. Compact.
   - `branch-env-files` — `.env` and `.env.staging` already live on the host; the workflow picks one with `ENV_FILE=".env"` or `".env.staging"` based on the deploy branch and passes via `docker compose --env-file`. Best for dual prod/staging on one box.

6. **CI runner.** Ask. Default `ubuntu-latest`, but offer `ubuntu-22.04`, `ubuntu-24.04`, self-hosted, ARM. Treat as a `{{RUNNER}}` token — never hardcode `ubuntu-latest`.

7. **Deploy branches.** Default `main` for prod. Ask if a `staging` branch should also be wired up.

8. **Detect existing migration setup.** Look for: `drizzle.config.ts`, `prisma/schema.prisma`, `alembic.ini`, `db/migrate/`, `migrations/*.sql`, `schema.sql` + Turso CLI usage, `pyproject.toml` referencing alembic, etc. If found, adapt to it.

9. **If no setup detected, ask migration mode + tool.** See "Migration tool reference" below.

10. **Healthcheck.** Default yes for `source-to-host` (curl `/health` after `up -d`), optional for `registry-first`, skip for git-auto-deploy targets unless the user wants one.

11. **Generate the files.** Substitute tokens, emit the appropriate set.

## Placeholder tokens

Use these in every template you adapt:

| Token | Example value | Notes |
|---|---|---|
| `{{SERVICE_NAME}}` | `widget-api` | Compose service name + image base name |
| `{{IMAGE_NAME}}` | `ghcr.io/owner/widget-api` | Full image ref (registry-first) or local tag (source-to-host) |
| `{{PORT}}` | `8000` | Internal container port |
| `{{HOST_PORT}}` | `8010` | Optional host port if different |
| `{{DEPLOY_BRANCH}}` | `main` | Workflow trigger branch |
| `{{STAGING_BRANCH}}` | `staging` | Optional |
| `{{RUNNER}}` | `ubuntu-latest` | `runs-on:` value |
| `{{LANG}}` | `node` / `bun` / `python` | Picks Dockerfile family |
| `{{REGISTRY}}` | `ghcr.io` | For `registry-first` only |
| `{{REGISTRY_LOGIN_ACTION}}` | `docker/login-action@v3` | Same for GHCR / Docker Hub; different for ECR (`aws-actions/amazon-ecr-login`) |
| `{{HOST_PATH}}` | `/opt/{{SERVICE_NAME}}` | Where SCP drops files on the host |
| `{{HEALTH_PATH}}` | `/health` | For the healthcheck curl |

## Secret naming — provider-neutral by default

In the agnostic `ssh-host-docker-caddy` mode, use **`DEPLOY_*`** secret names only. Never `EC2_HOST`, `AWS_*`, `DO_*`.

| Purpose | Secret name |
|---|---|
| Target hostname / IP | `DEPLOY_HOST` |
| SSH username | `DEPLOY_USER` |
| SSH private key | `DEPLOY_SSH_KEY` |
| SSH port (optional) | `DEPLOY_PORT` (default `22`) |
| Registry token (registry-first) | `GHCR_PAT` / `DOCR_TOKEN` / `ECR_*` — depends on registry |

App-level secrets (`DATABASE_URL`, `JWT_SECRET`, etc.) keep whatever names the project uses.

Cloud-locked modes (`do-app-platform`, `aws-ecs`, `gcp-cloud-run`) are the only place provider-specific secret names belong.

## Migration tool reference

The skill supports any migration paradigm. Detect first, then ask.

**WHERE migrations run:**
- `ci-applied` — workflow step runs them after `up -d`. Add a migrate service to compose or a CLI invocation in the SSH script.
- `developer-applied` — devs run manually before/after deploy. Workflow stays DB-free.
- `none` — no migration scaffolding emitted.

**WHICH tool — first-class scaffolds in `templates/migrations/`:**

| Tool | Path | When |
|---|---|---|
| Drizzle | `migrations/drizzle/` | Node/TS + Postgres/MySQL/SQLite, usually `developer-applied`. Default for Supabase Postgres stacks. |
| Prisma | `migrations/prisma/` | Node/TS + many DBs. Works in either mode. |
| Alembic | `migrations/alembic/` | Python + SQLAlchemy. |
| dbmate | `migrations/dbmate/` | DB-agnostic SQL files, `ci-applied` as a one-off compose service. |
| golang-migrate | `migrations/golang-migrate/` | DB-agnostic CLI/Go lib. |
| Raw psql | `migrations/raw-psql/` | Postgres-only, zero dependencies. `migrate.sh` loops `migrations/NNN_*.sql` in order, tracks applied versions in a `schema_migrations` table. |

**Documented (one-line workflow step, no scaffold needed):**

- `node-pg-migrate`: `npx node-pg-migrate up` (Postgres only).
- TypeORM: `npm run typeorm migration:run` (configure `ormconfig` first).
- Flyway: `flyway migrate -url=$DATABASE_URL` (CLI on host or in compose).
- Liquibase: `liquibase update` (requires changelog setup).
- Supabase CLI: `supabase db push` (developer-applied) or `supabase migration up` (against linked project).
- Django / Rails / Laravel: `manage.py migrate` / `rake db:migrate` / `php artisan migrate` — drop into the SSH step or container entrypoint.
- Turso CLI: `turso db shell <db-name> < src/db/schema.sql` (developer-applied, raw libSQL pattern). Pair with `@libsql/client` or `drizzle-orm/libsql` in the app code.
- Custom: emit a compose-service stub and workflow step the user fills in.

**Rollback discipline:**
- Wrap raw-SQL migrations in `BEGIN; … COMMIT;`.
- Surface a "Rollback" section in the project's generated README explaining how to revert the last migration with the chosen tool.
- Never assume auto-rollback unless the tool documents it.

## Vercel + Turso flavor

When `vercel-serverless` is chosen, emit:
- `vercel.json` — functions config, regions, redirects (template at `templates/vercel/vercel.json`).
- `/api/example.ts` — serverless function shape with proper request/response (template at `templates/vercel/api-handler-example.ts`).
- `lib/db.ts` — Turso client. Two flavors:
  - `templates/vercel/lib-db-turso.ts` — direct `@libsql/client`.
  - `templates/vercel/lib-db-drizzle-libsql.ts` — `drizzle-orm/libsql` adapter.
- Schema deployment: emit `src/db/schema.sql` and a README block on `turso db shell <db> < src/db/schema.sql` for manual application.

Env vars expected:
- `TURSO_DATABASE_URL` (e.g. `libsql://your-db.turso.io`)
- `TURSO_AUTH_TOKEN`

Set them with `vercel env add` for each environment (development / preview / production). No GitHub Secrets, no GH Actions workflow.

## DO-NOT list

These are non-negotiable:

- ❌ Never inline real secret values into any generated file. Only `${{ secrets.* }}` references in workflows.
- ❌ Never hardcode hostnames, IPs, or domains. Tokens or secrets only.
- ❌ Never `docker pull` without a `docker login` step first in `registry-first` mode.
- ❌ Never include a `docker login` step in `source-to-host` mode (no registry is used).
- ❌ Never skip `restart: unless-stopped` on production services in compose.
- ❌ Never commit `.env` files. Always ensure `.env` is in `.gitignore` for the project.
- ❌ Never assume `ubuntu-latest` — ask.
- ❌ Never use cloud-provider-specific secret names (`EC2_HOST`, `AWS_*`, `DO_*`) in the agnostic `ssh-host-docker-caddy` mode. Use `DEPLOY_*` only.
- ❌ Never emit a `.github/workflows/deploy.yml` in git-auto-deploy modes (Vercel, Render, Railway, Fly with `flyctl launch`).
- ❌ Always include `docker image prune -f` cleanup at the end of CI-driven deploy workflows.
- ❌ Always include a `healthcheck:` block on services that have a `/health` endpoint, or a Postgres/Redis healthcheck on dependencies.

## Output contract

When you finish:
- List every file you generated and where it goes (project-relative path).
- Show the secrets the user must add (`gh secret set` commands are fine).
- For `ssh-host-docker-caddy`, show the one-time host setup commands (`docker`, `docker compose plugin`, user added to `docker` group, `/opt/<service>` dir owned correctly).
- For `vercel-serverless +turso`, show the `vercel env add` and `turso db create` commands.
- Surface known caveats — for example, source-to-host means longer deploys (build runs on the target each time); branch-env-files means secrets sync is out-of-band.

Output is action-ready: the user should be able to commit the files, set the secrets, and have a working deploy on the next push.
