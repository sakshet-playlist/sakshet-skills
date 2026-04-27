# sakshet-skills

Personal Claude skills repository — productivity workflows for Sakshet Chavan.

## Skills

| Skill | Description |
|---|---|
| [`slack-triage`](./skills/slack-triage/) | Full Slack sweep — finds all unanswered mentions and open threads across all channels, classifies by priority, and sends a DM to self |

---

## Installing in Claude Desktop (one-time setup)

Open Claude Desktop → Customize → Skills → **+** next to Personal plugins.

Paste this repo path:
```
YOUR_GITHUB_USERNAME/sakshet-skills
```

Click **Sync** → **Install** on `slack-triage`. Done.

---

## Installing via GitHub CLI (Claude Code)

```bash
gh skill install YOUR_GITHUB_USERNAME/sakshet-skills slack-triage --agent claude-code --scope user
```

---

## Updating skills

### Claude Desktop
Go to Skills → find `slack-triage` → click **Sync** to pull latest from GitHub.

### GitHub CLI
```bash
gh skill update slack-triage
```

### Manual (if you cloned the repo)
```bash
cd ~/path/to/sakshet-skills
git pull
```

---

## Adding a new skill

Each skill is a folder inside `skills/` containing a `SKILL.md` file:

```
skills/
└── your-skill-name/
    └── SKILL.md       ← required
    └── references/    ← optional: docs, templates
    └── scripts/       ← optional: Python/bash helpers
```

`SKILL.md` must start with YAML frontmatter:

```yaml
---
name: your-skill-name
description: >
  What the skill does and when Claude should trigger it.
  Be specific — this is what Claude reads to decide whether to load the skill.
---

# Your Skill Name

[Instructions here...]
```

---

## Repository structure

```
sakshet-skills/
├── README.md
└── skills/
    └── slack-triage/
        └── SKILL.md
```
