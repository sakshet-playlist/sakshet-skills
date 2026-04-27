#!/bin/bash
# push-skill.sh
# Commits and pushes a skill update to GitHub.
# Usage: bash push-skill.sh <skill-name> [optional commit message]
#
# Examples:
#   bash push-skill.sh slack-triage
#   bash push-skill.sh slack-triage "Add older thread sweep logic"

set -e

SKILL_NAME="$1"
COMMIT_MSG="${2:-"Update $SKILL_NAME skill"}"

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: bash push-skill.sh <skill-name> [commit message]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/skills/$SKILL_NAME"

if [ ! -d "$SKILL_DIR" ]; then
  echo "❌  Skill '$SKILL_NAME' not found at $SKILL_DIR"
  exit 1
fi

cd "$SCRIPT_DIR"

git add "skills/$SKILL_NAME/"
git commit -m "$COMMIT_MSG" 2>/dev/null || { echo "ℹ️   Nothing to commit"; exit 0; }
git push

echo ""
echo "✅  '$SKILL_NAME' pushed to GitHub."
echo ""
echo "To sync in Claude Desktop:"
echo "  Customize → Skills → find '$SKILL_NAME' → Sync"
echo ""
echo "To update via GitHub CLI:"
echo "  gh skill update $SKILL_NAME"
