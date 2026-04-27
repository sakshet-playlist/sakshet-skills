#!/bin/bash
# add-skill.sh
# Adds a new skill folder and pushes to GitHub.
# Usage: bash add-skill.sh <skill-name>
#
# Example: bash add-skill.sh notion-triage
# This creates skills/notion-triage/SKILL.md with a starter template.

set -e

SKILL_NAME="$1"

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: bash add-skill.sh <skill-name>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/skills/$SKILL_NAME"

if [ -d "$SKILL_DIR" ]; then
  echo "❌  Skill '$SKILL_NAME' already exists at $SKILL_DIR"
  exit 1
fi

mkdir -p "$SKILL_DIR"

cat > "$SKILL_DIR/SKILL.md" << EOF
---
name: $SKILL_NAME
description: >
  [Describe what this skill does and when Claude should use it.
   Be specific — this description is what Claude reads to decide
   whether to load the skill.]
---

# ${SKILL_NAME^}

## Overview

[Describe what this skill does]

## Steps

[Add step-by-step instructions here]

## Rules

[Add any important constraints or rules]
EOF

echo "✅  Created $SKILL_DIR/SKILL.md"
echo ""
echo "Next steps:"
echo "  1. Edit the SKILL.md: open $SKILL_DIR/SKILL.md"
echo "  2. When ready, run: bash push-skill.sh '$SKILL_NAME'"
