# 📝 Blog Writing Formula

A reusable agent skill for writing engaging, high-quality technical blog posts for Dev.to, Hashnode, personal blogs, and beyond.

Built from the trenches of shipping real blog posts that get reads, reactions, and submissions to hackathons/challenges.

---

## Installation

### For Cline / Claude Dev Users

Add this skill to your MCP settings or copy the prompt into your system prompt:

```bash
# Clone the skill
git clone https://github.com/ShatilKhan/krompt.git

# Use the prompt in your agent
cat krompt/skills/blog-writing-formula/prompt.md
```

### For Claude Code Users (Skills CLI)

```bash
npx skills add ShatilKhan/krompt/skills/blog-writing-formula
```

### Manual Install

1. Copy `prompt.md` into your agent's system instructions
2. Copy `templates/` into your project workspace
3. Reference `examples/` for guidance

---

## What This Skill Does

Transforms raw project notes, architecture docs, and screenshots into a polished, publication-ready technical blog post using a battle-tested formula.

### The Formula

| Step | Purpose | Output |
|------|---------|--------|
| **1. The Hook** | Grab attention with a relatable problem + meme | First 3 paragraphs |
| **2. The Setup** | Introduce the tool/tech with zero assumed knowledge | "What Even Is X?" section |
| **3. The Hack** | Reveal the core insight or workaround | The "Aha!" moment |
| **4. The Product** | Show what you actually built | Architecture + screenshots |
| **5. The Why** | Explain why this matters to others | Universal lesson |
| **6. The Stack** | Quick-reference table + diagrams | TL;DR section |
| **7. The Gotchas** | Real lessons from production | Troubleshooting |
| **8. The Reference** | Copy-paste commands | Quick start |

---

## Templates

| Template | Use Case | File |
|----------|----------|------|
| `technical-hack.md` | "We found a workaround" stories | [templates/technical-hack.md](templates/technical-hack.md) |
| `tutorial-walkthrough.md` | Step-by-step how-to guides | [templates/tutorial-walkthrough.md](templates/tutorial-walkthrough.md) |
| `project-showcase.md` | "Look what I built" posts | [templates/project-showcase.md](templates/project-showcase.md) |
| `opinion-essay.md` | Hot takes and predictions | [templates/opinion-essay.md](templates/opinion-essay.md) |

---

## Directory Structure

```
blog-writing-formula/
├── README.md              # This file
├── skill.json             # Skill manifest for agent tools
├── prompt.md              # Core agent prompt (copy this!)
├── templates/
│   ├── technical-hack.md
│   ├── tutorial-walkthrough.md
│   ├── project-showcase.md
│   └── opinion-essay.md
└── examples/
    └── hijacking-openclaw/  # Real example from OpenClaw challenge
```

---

## Usage with Your Agent

### Prompt Pattern

When you want to write a blog, tell your agent:

> "Use the blog-writing formula. I want a [technical-hack] post about [topic].
> Here's my project docs: [paste docs].
> I have these screenshots: [list images].
> The deadline is [date]."

### Agent Instructions

The agent should:
1. Read `prompt.md` for the formula
2. Select the appropriate template from `templates/`
3. Generate diagrams (D2, Mermaid, or AntV MCP)
4. Draft in `drafts/<post-name>/`
5. Insert all images and diagrams
6. Output a publication-ready Markdown file

---

## License

MIT — use it, fork it, make it yours.
