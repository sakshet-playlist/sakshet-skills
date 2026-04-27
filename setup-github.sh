#!/bin/bash
# setup-github.sh
# Run this ONCE to push the skills repo to GitHub.
# Requires: git, gh (GitHub CLI) — install gh at https://cli.github.com

set -e

REPO_NAME="sakshet-skills"
REPO_DESC="Personal Claude skills — Slack triage and productivity workflows"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Skills Repo — GitHub Setup                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check dependencies
if ! command -v gh &>/dev/null; then
  echo "❌  GitHub CLI not found. Install it first:"
  echo "    brew install gh"
  echo "    Then run: gh auth login"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "❌  Not logged into GitHub CLI. Run: gh auth login"
  exit 1
fi

# Move into the repo folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Init git if not already
if [ ! -d ".git" ]; then
  git init
  echo "✅  Git initialized"
fi

# Stage everything
git add .
git commit -m "Initial commit: slack-triage skill" 2>/dev/null || echo "ℹ️   Nothing new to commit"

# Create GitHub repo and push
echo ""
echo "Creating GitHub repository: $REPO_NAME"
gh repo create "$REPO_NAME" \
  --public \
  --description "$REPO_DESC" \
  --source=. \
  --remote=origin \
  --push

echo ""
echo "✅  Pushed to GitHub!"
echo ""

# Print the install instructions
GH_USER=$(gh api user --jq .login)
echo "╔══════════════════════════════════════════════╗"
echo "║  Install your skill from GitHub:             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Claude Desktop:"
echo "  Customize → Skills → + → paste: $GH_USER/$REPO_NAME → Sync → Install"
echo ""
echo "GitHub CLI (Claude Code):"
echo "  gh skill install $GH_USER/$REPO_NAME slack-triage --agent claude-code --scope user"
echo ""
echo "Repo URL: https://github.com/$GH_USER/$REPO_NAME"
echo ""
