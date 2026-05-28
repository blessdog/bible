#!/usr/bin/env bash
#
# init-project.sh — bootstrap a new project per the bible Day-0 Checklist
#
# Usage:
#   init-project.sh <project-name>
#
# Creates a new project directory in the current working directory with:
#   - git initialized + project-start tag
#   - README.md, .gitignore, .editorconfig
#   - CLAUDE.md template (locked decisions + working agreement + pre-flight)
#   - .claude/settings.json with defaultMode: plan
#   - shared/ directory scaffolded for SSOT growth
#
# Refuses to overwrite an existing directory. Idempotent at the
# parent-directory level — safe to re-run if it fails partway.

set -euo pipefail

# Absolute path to the bible directory (where this script lives). Used to
# bake an absolute reference into each new project's CLAUDE.md so Claude
# sessions in the new project know where to find the universal principles.
BIBLE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [ $# -lt 1 ]; then
  echo "usage: init-project.sh <project-name>" >&2
  exit 1
fi

PROJECT="$1"
DIR="$PROJECT"

if [ -e "$DIR" ]; then
  echo "error: $DIR already exists" >&2
  exit 1
fi

echo "→ creating $DIR"
mkdir -p "$DIR"
cd "$DIR"

echo "→ git init"
git init -q -b main

# ─── README.md ─────────────────────────────────────────────────────────
cat > README.md <<EOF
# $PROJECT

> One-paragraph description of what this project IS. Frame it so a reader
> with no context (human or AI) understands the goal, the constraint, and
> who uses it.

## Status

Newly bootstrapped. See \`CLAUDE.md\` for locked decisions and working
agreement.

## Setup

(Fill in once dependencies are added.)
EOF

# ─── .gitignore ────────────────────────────────────────────────────────
cat > .gitignore <<'EOF'
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/*
!.vscode/extensions.json
.idea/
*.swp
*.swo

# Node
node_modules/
dist/
build/
*.log
npm-debug.log*

# Env
.env
.env.local
.env.*.local

# Local working artifacts (NOT load-bearing source)
outputs/
tmp/
scratch/

# Python
__pycache__/
*.py[cod]
.venv/
venv/
EOF

# ─── .editorconfig ─────────────────────────────────────────────────────
cat > .editorconfig <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false
EOF

# ─── CLAUDE.md ─────────────────────────────────────────────────────────
cat > CLAUDE.md <<EOF
# $PROJECT — Claude working agreement

## Universal principles

This project follows the architectural rules, version-control hygiene,
and AI-collaboration patterns documented in the **project bible** at:

- Local:  $BIBLE_DIR/README.md
- GitHub: https://github.com/blessdog/bible (public mirror)

Consult the bible BEFORE suggesting new patterns or proposing
architectural changes. The terms it uses (SSOT, shotgun surgery,
make-illegal-states-unrepresentable, don't-rewrite-from-scratch, plan
mode, hard-pivot tags, etc.) are search handles — use them rather than
re-inventing.

## What this project is

(One paragraph. Same intent as README, framed for an AI agent. What it
IS, who uses it, the single most-load-bearing constraint.)

## Locked decisions

These are NOT up for re-litigation in a session. Argue for changes in
writing — in this file — not in code.

- (Add entries as decisions are made. Examples:
  "language: TypeScript with strict null checks",
  "no class-based React components",
  "all timestamps in UTC, ISO-8601",
  "art direction: <specific reference>",
  "no client-side secrets — Edge Functions only.")

## How I want to work with you

- Default to plan mode for non-trivial changes (already wired via
  \`.claude/settings.json\`).
- Pressure-test before agreeing. Argue the "we don't need this" side
  before building. Sycophancy is not helpful.
- Mentor mode: name industry-standard principles, surface trade-offs,
  link to anti-pattern names. The collaboration is paired engineering,
  not task offloading.
- Small commits. One concern per commit. Subject lines as search bait.
- Verify against ground truth, not summaries — when reading multi-stage
  pipeline output, read the actual artifact at each stage.

## Pre-flight: read these before touching anything load-bearing

List the files that govern the most consequential behavior of this
project. Read them in order, check they agree, BEFORE editing creative
or architectural surfaces. Add to this list as the project grows.

- (path/to/load-bearing-file-1) — why it matters
- (path/to/load-bearing-file-2) — what conflicts to watch for
EOF

# ─── .claude/settings.json ─────────────────────────────────────────────
mkdir -p .claude
cat > .claude/settings.json <<'EOF'
{
  "permissions": {
    "defaultMode": "plan"
  }
}
EOF

# ─── shared/ ───────────────────────────────────────────────────────────
mkdir -p shared
cat > shared/README.md <<'EOF'
# shared/

Single Source of Truth (SSOT) layer.

Anything that appears in more than one place in this project belongs
here:
- Config: URLs, API keys (or their references), provider IDs, model
  names, magic numbers.
- Types / schema definitions.
- Cross-cutting utilities (encoders, formatters, error shapes).
- Creative direction (style guides, locked tone rules, system prompts).

What does NOT go here:
- Logic specific to exactly one consumer.
- Anything used by only one file (premature abstraction is worse than
  duplication).
- "Might be reused someday" — wait for the second use case.

This directory exists from Day 0 because the architectural commitment
to SSOT is what prevents shotgun surgery (Martin Fowler, *Refactoring*)
once the project gets complex enough to have multiple consumers of the
same fact.
EOF

# ─── First commit + tag ────────────────────────────────────────────────
echo "→ first commit"
git add .
git commit -q -m "Day 0: project bootstrap

Initialized per the bible Day-0 Checklist:
- README.md, .gitignore, .editorconfig
- CLAUDE.md template (locked decisions, working agreement, pre-flight)
- .claude/settings.json with defaultMode: plan
- shared/ directory scaffolded for SSOT growth

Next: fill in CLAUDE.md sections with project-specific decisions, add
language/framework setup, then start writing feature code in small
commits."

git tag -a project-start -m "Day 0 bootstrap per the project bible."

# ─── Done ──────────────────────────────────────────────────────────────
echo ""
echo "✓ $PROJECT bootstrapped"
echo ""
echo "Next steps:"
echo "  1. cd $DIR"
echo "  2. Open CLAUDE.md — fill in 'What this project is' and 'Locked decisions'"
echo "  3. Add language/framework setup (package.json, Cargo.toml, etc.)"
echo "  4. Start writing feature code in small commits"
echo ""
echo "Tags:"
echo "  project-start  (this state — recoverable via 'git checkout project-start')"
