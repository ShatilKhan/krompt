# Hijacking OpenClaw with Claude

My boss has been nagging me about "being more verbal" and "showing proof of work" and here I was pushing code when no one was seeing it.

![gigachadvscrawny](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/p0f5g1b6sb4hwvnaotwl.png)

So I decided to try out OpenClaw for as our product manager.

I have no idea how to set it up or how it works. I had only seen tiktoks saying both good and bad stuff. And a Fireship video I saw weeks ago. That's pretty much my knowledge on this crab.

So today we make it folks!
Our Clawfficer!

![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/lpjnmyh09klfyu1wfat1.png)

---

## The Problem: We Had Claude Code, But Not Claude

Here's the thing. My company gave us access to **Claude Code** (the CLI tool) through our dev environments. But they didn't give us **Claude web accounts** or API keys. No `console.anthropic.com`. No OAuth flow. No nothing.

So I'm sitting there with this powerful CLI tool installed, but I can't even log in the "normal" way because that requires a web account.

Sound familiar? If your office IT is anything like mine, you probably have access to tools but not the accounts that make them "officially" work.

Time to mad-scientist our way through this.

---

## What Even Is OpenClaw?

Before we get into the hack, let's talk about what we're building with.

OpenClaw is basically a local agent harness — think of it as a crab shell that lets you run Claude with superpowers. It gives you:
- File operations
- MCP tool access
- Subagents
- Scheduling
- Long-running agent state

But here's the catch: OpenClaw needs Claude to actually *do* the thinking. And Claude usually needs an API key or web OAuth to work.

Except... we already have Claude Code installed. And Claude Code has a trick.

---

## The Symlink Hack

When you install Claude Code globally:

```bash
npm install -g @anthropic-ai/claude-code
```

It creates a `claude` binary in your PATH. But here's what most people don't realize: **this binary carries its own authentication**.

When you run `claude /login` (which we *could* do because we had the CLI), it opens a browser and does OAuth with your Claude Pro/Max subscription. It then stores a refresh token at:

```
~/.claude/.credentials.json
```

Now here's the beautiful part: **Claude Code can run in headless mode**.

```bash
echo "Summarize these commits" | claude -p --output-format=text
```

No API key. No `ANTHROPIC_API_KEY` env var. No web console. Just the OAuth token that Claude Code manages itself, auto-refreshing forever.

We basically **hijacked** the Claude Code CLI's authentication mechanism and piped it into our OpenClaw workflow. The CLI becomes our "API layer" without us ever touching an API key.

![Clawfficer Architecture Diagram](diagram-clawfficer-architecture.svg)

*Diagram: How Claude Code's OAuth flows into our OpenClaw setup without ever exposing an API key*
```

---

## Meet the Clawfficer

So what does our "mad science" actually *do*?

We built a Discord bot that acts as our product manager. We call it the **Clawfficer**.

Here's what it handles:

### Flow 1: GitHub → Discord (Zero Code)
Native GitHub webhooks push to our `#github-updates` channel. Commits, PRs, issues — everything shows up automatically. No bot code needed.

### Flow 2: Suggestion → GitHub Issue
Someone drops an idea in `#roadmap`: "We should add dark mode to medihelp. Assign Shatil."

The bot:
1. Listens to the message
2. Fuzzy-matches which repo "medihelp" refers to
3. Parses "Shatil" into a GitHub username
4. Creates the issue with the right assignee
5. Replies with the issue link and a ✅ reaction

![The Three Flows](diagram-three-flows.svg)

*Diagram: The three flows of the Clawfficer — notifications, suggestions, and digests*

Here are some screenshots from our actual Discord channels:

![Screenshot 1](screenshot-1.jpg)
![Screenshot 2](screenshot-2.jpg)
![Screenshot 3](screenshot-3.jpg)

### Flow 3: The Digest (Where the Magic Happens)
Every day at 9 AM and every Sunday at 10 AM, the bot pulls activity from all 8 of our repos across **all branches** (not just main — we learned that lesson the hard way).

Then it pipes all that data into:

```bash
claude -p --output-format=text
```

And Claude spits back a human-readable prose summary. Not bullet points. Not raw JSON. Actual sentences like:

> "Medihelp saw 12 commits across 3 branches this week, mostly schema migrations by Mahim. The eyecraft landing page got its first PR review."

The bot posts this to `#roadmap`. My boss sees it. I stop getting nagged about "proof of work."

Everyone wins.

---

## Why This Matters for Office Workers Everywhere

Let's be real: a lot of companies are going to give developers access to AI tools without giving them the "full" account experience. Maybe it's:
- Security policies that block API key creation
- Budget constraints that limit web console access
- IT departments that haven't caught up yet

The Claude Code symlink approach means you can:
1. **Use your existing subscription** (Claude Pro/Max) — same billing bucket as your interactive usage
2. **Run headlessly** in scripts, cron jobs, and bots
3. **Never handle an API key** — OAuth tokens live in `~/.claude/` and auto-refresh
4. **Deploy anywhere** that has Node.js and your user context

It's not "officially supported" as an API replacement. But it works. And for internal tools that need to "just work" without procurement battles, that's gold.

---

## The Stack

![Tech Stack Mind Map](diagram-tech-stack.svg)

*Mind map: The Clawfficer tech stack and why each piece exists*

| Layer | Tool | Why It Exists |
|-------|------|---------------|
| LLM Engine | Claude Code CLI (`claude -p`) | Our "API" — uses subscription OAuth, no API key |
| Agent Harness | OpenClaw | Workspace, scheduling, and tool scaffolding |
| Bot Runtime | Node.js + discord.js | Discord integration and cron scheduling |
| GitHub API | Classic PAT | Repo access for issues, commits, PRs |
| Process Manager | systemd user service | Auto-start on boot, restart on crash |
| Secrets | Files outside repo | `.env-roadmap` and webhook URLs gitignored |

---

## Running It Like a Service

The bot runs as a **systemd user service**, which means:
- It starts automatically on boot
- It restarts if it crashes
- It survives logout (via `loginctl enable-linger`)
- The key trick: we override `PATH` in the systemd unit so it can find the `claude` symlink

Without that PATH override, systemd's stripped-down environment can't find Claude Code, and the whole digest flow breaks. It's a one-line fix that took us an embarrassing amount of time to figure out.

![systemd service diagram](diagram-systemd.svg)

*Diagram: How the systemd service wraps the Node.js bot and keeps it alive*

---

## What We Learned

### 1. Branch Coverage Matters
GitHub's `/commits` endpoint defaults to the default branch. If your team works on feature branches (and they should), your digest will look empty even when people are pushing code.

**Fix:** Iterate all branches, dedupe by commit SHA. Obvious in hindsight, painful in production.

### 2. The OAuth Token is Everything
The `~/.claude/.credentials.json` file is the single point of auth failure. If it expires or gets corrupted, `claude -p` exits with code 1 and your digest falls back to bullet points.

**Fix:** Run `claude` interactively once to re-auth. The CLI handles refresh tokens automatically after that.

### 3. systemd PATH is Not Your Shell PATH
Your interactive shell has `claude` in PATH. systemd doesn't. Explicitly set `Environment=PATH=...` in your unit file or the spawn fails silently.

---

## What's Next

The Clawfficer is intentionally minimal. We deliberately didn't build:
- Slash commands (`/roadmap-add` instead of parsing every message)
- Message state persistence (restarts drop in-flight suggestions)
- Multi-tenant config (repos and devs are hardcoded)
- LLM-powered "state of all projects" top-level summary

But the foundation is there. And more importantly, the **authentication pattern** is there.

If you're in an office where you have the tools but not the "official" access, this symlink hack opens doors. Claude Code's CLI isn't just an interactive coding assistant — it's a headless LLM engine that happens to already be authenticated.

Use it.

---

## Quick Reference

```bash
# Install Claude Code (creates the symlink)
npm install -g @anthropic-ai/claude-code

# Auth once
claude /login

# Use forever, headlessly
echo "your prompt" | claude -p --output-format=text
```

---

*Shatil Khan builds things at Anchorblock and argues with crabs on the internet. Follow for more questionable engineering decisions that somehow work.*

#openclaw #claude #ai #discord #github #productivity #devops #javascript
