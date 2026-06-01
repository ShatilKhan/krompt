# Cover Letter Writing Skill

A reusable agent skill that writes cover letters in **your own voice**. It captures tone and structural patterns only — it does NOT bake in your projects, employers, or skill stack (those change). You supply the job description and a short paragraph about your current work at use time; the skill supplies the discipline.

Three modes:
- **`application`** (default) — standard role/company letters (SWE, full-stack, AI engineer, platform, ops).
- **`research`** — research engineer / lab / NLP positions.
- **`scholarship`** — community / scholarship multi-prompt essays.

---

## Installation

### One-liner (auto-detects your agent)

```bash
curl -fsSL https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/krompt-cover-letter/install.sh | bash
```

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
curl -fsSL <url>/install.sh | bash -s -- claude-code --scope user
curl -fsSL <url>/install.sh | bash -s -- cursor
curl -fsSL <url>/install.sh | bash -s -- generic --force
```

Re-runs are idempotent. Pass `--force` to overwrite an existing block. Bracketed with `<!-- krompt:krompt-cover-letter:start/end -->` markers for clean replacement.

---

## How to use it

Once installed, hand your agent a message like:

> "Use the cover-letter skill in `application` mode.
> JD: [paste the job description]
> Current work: I'm shipping a [thing] using [tech], and recently built a [feature] that [solved X]."

You'll get back the **body only** — no salutation, no header, no signature. Paste your own contact block and `Dear …,` / sign-off around it.

For research roles, switch the mode:

> "Use the cover-letter skill in `research` mode. JD: […]. Current work: […]."

For scholarship / community essays:

> "Use the cover-letter skill in `scholarship` mode. Here are the prompts: 1) … 2) … 3) … . Current work and community involvement: […]."

---

## What the skill captures

- **Voice tics**: confident-not-boastful register, conversational contractions, sparing em-dash use, paired-adjective signature ("scalable, modern"; "clean, testable"), long-clause sentences ~25–40 words, technical specificity over buzzword stacks.
- **Structural patterns**: hook → primary anchor → secondary surface → (cross-functional) → bridge → closer for `application`; methodology-led with a motivating-problem paragraph for `research`; per-prompt micro-essays with forward-looking impact statements for `scholarship`.
- **A DO-NOT list** of generic LLM cover-letter failure modes (no "I am thrilled", no three-adjective stacks, no invented metrics, no JD-restating).

What it explicitly does NOT capture: any project names, employer names, certifications, links, or accomplishments. Those go in at use time so the skill stays current as your work evolves.

---

## License

MIT.
