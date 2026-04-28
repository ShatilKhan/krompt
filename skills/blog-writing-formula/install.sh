#!/usr/bin/env bash
# Blog Writing Formula Skill — Universal Installer
# Auto-detects: Claude Code, Cursor, Cline, Windsurf, Copilot, Aider, Generic
# Works locally OR piped:  curl -fsSL <raw>/install.sh | bash

set -eo pipefail

SKILL_NAME="blog-writing-formula"
SKILL_VERSION="1.1.0"
SKILL_DESC="Write engaging, high-quality technical blog posts using a battle-tested 8-step formula."
SKILL_TRIGGERS="write a blog post|use the blog writing formula|draft a dev.to post|write a technical blog"
RAW_BASE="${KROMPT_RAW_BASE:-https://raw.githubusercontent.com/ShatilKhan/krompt/main/skills/${SKILL_NAME}}"
SOURCE_FILE="prompt.md"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[skill]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; exit 1; }

usage() {
  cat <<EOF
${SKILL_NAME} v${SKILL_VERSION}

Usage:
  install.sh [target] [--scope project|user] [--force] [--with-templates]

Targets (auto-detected if omitted):
  claude-code   .claude/skills/<name>/SKILL.md
  cursor        .cursor/rules/<name>.mdc
  cline         .clinerules/<name>.md
  windsurf      .windsurf/rules/<name>.md
  copilot       .github/copilot-instructions.md   (appended)
  aider         CONVENTIONS.md                    (appended)
  generic       AGENTS.md                         (appended)

Examples:
  bash install.sh
  bash install.sh cursor --with-templates
  curl -fsSL ${RAW_BASE}/install.sh | bash
EOF
}

script_dir() {
  local src="${BASH_SOURCE[0]:-}"
  [[ -z "$src" || "$src" == "bash" ]] && { echo ""; return; }
  cd "$(dirname "$src")" 2>/dev/null && pwd
}

fetch() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$url"
  elif command -v wget >/dev/null 2>&1; then wget -qO- "$url"
  else err "need curl or wget"; fi
}

emit_source() {
  local dir; dir=$(script_dir)
  if [[ -n "$dir" && -f "$dir/$SOURCE_FILE" ]]; then
    cat "$dir/$SOURCE_FILE"
  else
    fetch "$RAW_BASE/$SOURCE_FILE"
  fi
}

already_installed() { local f="$1"; [[ -f "$f" ]] && grep -q "krompt:${SKILL_NAME}" "$f" 2>/dev/null; }

append_block() {
  local dest="$1" body="$2"
  mkdir -p "$(dirname "$dest")"
  if already_installed "$dest" && [[ "${FORCE:-0}" != "1" ]]; then
    warn "$dest already contains ${SKILL_NAME}. Use --force to reinstall."; return 1
  fi
  if already_installed "$dest" && [[ "${FORCE:-0}" == "1" ]]; then
    local tmp; tmp=$(mktemp)
    awk -v sp="<!-- krompt:${SKILL_NAME}:start" -v ep="<!-- krompt:${SKILL_NAME}:end" '
      index($0, sp)==1 {skip=1; next} index($0, ep)==1 {skip=0; next} !skip' "$dest" > "$tmp"
    mv "$tmp" "$dest"
  fi
  {
    [[ -s "$dest" ]] && echo ""
    echo "<!-- krompt:${SKILL_NAME}:start v${SKILL_VERSION} -->"
    echo "$body"
    echo "<!-- krompt:${SKILL_NAME}:end -->"
  } >> "$dest"
}

write_file() {
  local dest="$1" body="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" && "${FORCE:-0}" != "1" ]]; then warn "$dest exists. Use --force."; return 1; fi
  printf '%s\n' "$body" > "$dest"
}

copy_templates() {
  [[ "${WITH_TEMPLATES:-0}" == "1" ]] || return 0
  local dest_dir="$1"
  mkdir -p "$dest_dir/templates"
  local names="technical-hack tutorial-walkthrough project-showcase opinion-essay"
  local dir; dir=$(script_dir)
  for n in $names; do
    if [[ -n "$dir" && -f "$dir/templates/${n}.md" ]]; then
      cp "$dir/templates/${n}.md" "$dest_dir/templates/${n}.md"
    else
      fetch "$RAW_BASE/templates/${n}.md" > "$dest_dir/templates/${n}.md" || true
    fi
  done
  ok "Templates → $dest_dir/templates/"
}

install_claude_code() {
  local body; body=$(emit_source)
  local base
  if [[ "${SCOPE:-project}" == "user" ]]; then base="$HOME/.claude/skills"; else base=".claude/skills"; fi
  local dir="$base/$SKILL_NAME"
  mkdir -p "$dir"
  cat > "$dir/SKILL.md" <<EOF
---
name: ${SKILL_NAME}
description: ${SKILL_DESC}
---

${body}
EOF
  copy_templates "$dir"
  ok "Claude Code skill → $dir/SKILL.md"
}

install_cursor() {
  local body; body=$(emit_source)
  local dest=".cursor/rules/${SKILL_NAME}.mdc"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" && "${FORCE:-0}" != "1" ]]; then warn "$dest exists. Use --force."; return 1; fi
  cat > "$dest" <<EOF
---
description: ${SKILL_DESC}
globs:
alwaysApply: false
---

${body}
EOF
  copy_templates ".cursor/rules"
  ok "Cursor rule → $dest"
}

install_cline() {
  local body; body=$(emit_source)
  if [[ -d ".clinerules" || ! -f ".clinerules" ]]; then
    write_file ".clinerules/${SKILL_NAME}.md" "$body" && ok "Cline rule → .clinerules/${SKILL_NAME}.md"
    copy_templates ".clinerules"
  else
    append_block ".clinerules" "$body" && ok "Cline rule appended → .clinerules"
  fi
}

install_windsurf() {
  local body; body=$(emit_source)
  write_file ".windsurf/rules/${SKILL_NAME}.md" "$body" && ok "Windsurf rule → .windsurf/rules/${SKILL_NAME}.md"
  copy_templates ".windsurf/rules"
}

install_copilot() { local body; body=$(emit_source); append_block ".github/copilot-instructions.md" "$body" && ok "Copilot → .github/copilot-instructions.md"; }
install_aider()   { local body; body=$(emit_source); append_block "CONVENTIONS.md" "$body" && ok "Aider conventions → CONVENTIONS.md"; }
install_generic() { local body; body=$(emit_source); append_block "AGENTS.md" "$body" && ok "Generic agent rules → AGENTS.md"; }

detect_target() {
  # Project-local markers first (highest signal of intent for THIS repo)
  if [[ -d ".claude" ]]; then echo "claude-code"; return; fi
  if [[ -d ".cursor" || -f ".cursorrules" ]]; then echo "cursor"; return; fi
  if [[ -d ".clinerules" || -f ".clinerules" || -d ".cline" ]]; then echo "cline"; return; fi
  if [[ -d ".windsurf" || -f ".windsurfrules" ]]; then echo "windsurf"; return; fi
  if [[ -f ".github/copilot-instructions.md" ]]; then echo "copilot"; return; fi
  if [[ -f ".aider.conf.yml" || -f "CONVENTIONS.md" ]]; then echo "aider"; return; fi
  # User-home fallback (Claude Code installed globally but no project markers yet)
  if [[ -d "$HOME/.claude/skills" ]]; then echo "claude-code"; return; fi
  echo "generic"
}

TARGET=""; SCOPE="project"; FORCE=0; WITH_TEMPLATES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --user)  SCOPE="user"; shift ;;
    --force) FORCE=1; shift ;;
    --with-templates) WITH_TEMPLATES=1; shift ;;
    claude-code|cursor|cline|windsurf|copilot|aider|generic) TARGET="$1"; shift ;;
    *) err "Unknown arg: $1 (try --help)" ;;
  esac
done
export SCOPE FORCE WITH_TEMPLATES

main() {
  echo "=========================================="
  echo "  ${SKILL_NAME} v${SKILL_VERSION}"
  echo "=========================================="
  [[ -z "$TARGET" ]] && TARGET=$(detect_target)
  local flags="scope: $SCOPE"
  [[ "$FORCE" == "1" ]] && flags="$flags, force"
  [[ "$WITH_TEMPLATES" == "1" ]] && flags="$flags, +templates"
  log "Target: $TARGET  ($flags)"

  case "$TARGET" in
    claude-code) install_claude_code ;;
    cursor)      install_cursor ;;
    cline)       install_cline ;;
    windsurf)    install_windsurf ;;
    copilot)     install_copilot ;;
    aider)       install_aider ;;
    generic)     install_generic ;;
    *) err "Unknown target: $TARGET" ;;
  esac

  echo ""
  log "Trigger phrases: ${SKILL_TRIGGERS//|/, }"
  log "Tip: re-run with --with-templates to also copy the 4 blog templates."
}
main
