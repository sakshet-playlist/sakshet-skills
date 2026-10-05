---
name: log-session
description: >
  Append a structured entry for the current session to Sakshet's session log
  (Claude Projects/sessions.md), in one fixed format and in the right place
  (newest first), then check whether the session produced anything that should
  update the global CLAUDE.md. Use when Sakshet says "log this session", "log it",
  "wrap this session", "EOD", "session over", "save this to the log", or at the
  end of any substantial working session, per his CLAUDE.md instruction to update
  the session log at the end of every session.
---

# Log Session

## Files

- Session log: `/Users/sakshet.chavan/Workspace/Claude Projects/sessions.md`
- Global CLAUDE.md (canonical): `/Users/sakshet.chavan/Workspace/Claude Projects/CLAUDE.md`
- Handoff docs, when a session writes one, live next to the project files in
  `Claude Projects/<project>/`, named `<topic>-handoff-YYYY-MM-DD.md`.

## Steps

### 1. Gather the facts from this session

Only use what actually happened in the conversation. Do not infer outcomes, sent
messages, or approvals that were not confirmed.

- **Date**: today's ISO date. If the work spanned days, use `YYYY-MM-DD/DD`
  (same month) or `YYYY-MM-DD/MM-DD` (across months).
- **Session ID**: the 8-char prefix if visible, otherwise `*(see context)*`.
- **Topic**: a short title naming the project and the outcome, e.g.
  `Prime IV Reconciliation: Definitions Settled, Docs Rebuilt`.
- **Project tag**: the project from CLAUDE.md Active Projects this belongs to
  (e.g. `Booker Analytics`, `Credit Account Reporting`, `Partner API Docs`,
  `CF2`, `Tooling`). This is what makes monthly recaps easy.

### 2. Write the entry in this exact format

```markdown
### YYYY-MM-DD | <session id> | <Project tag>: <Topic>

**What happened:**
3-6 sentences. What was investigated, built, decided, shipped. Name the
evidence (code path, Sigma/Snowflake object, ticket) behind any finding.

**Shipped / decided:**
- Bullets for anything that is now live or a decision that was made, with date.
  Omit the section if nothing shipped or was decided.

**Corrections:**
- Anything this session found wrong in an earlier session, doc, or claim.
  Omit if none.

**Key artifacts:**
- Notion: "<page title>" (`<page id>`) - what changed
- ADO #<id> - what it is
- `Claude Projects/<path>` - what it is

**Open items:**
- [ ] Specific, actionable, with an owner where known. Mark anything drafted but
      NOT sent (Slack, email) explicitly as not sent.

**Full handoff:** `Claude Projects/<path>` (only if a handoff doc was written)

---
```

Rules for the content:
- No em dashes anywhere. Use commas, colons, or hyphens.
- Terse, Sakshet's voice. No narration of tool calls.
- Use Booker terminology from CLAUDE.md (Partner/Customer vs Consumer).
- A lesson about tooling goes in as one `**Lesson (tooling):**` line before
  `**Key artifacts:**`, only if it would change how a future session works.

### 3. Insert it in the right place

1. Read `sessions.md`.
2. Find the `## Sessions` heading and the `---` line directly after it.
3. Insert the new entry immediately after that `---`, so it becomes the first
   entry. Never append to the bottom of the file.
4. If an entry for the same topic and date already exists (a second log call in
   the same session), update that entry in place instead of adding a duplicate.
5. Do not edit or reformat any other entry.

### 4. Check for CLAUDE.md drift

Read the canonical CLAUDE.md and check whether this session produced:
- a new project, or a status change on an existing one (shipped, paused,
  deprioritized, new timeline)
- a new gate or Notion page ID worth recording
- a new repo under `~/Workspace/Booker/`
- new terminology or a corrected definition
- a change in how Sakshet wants Claude to work

If yes, show a short list of the proposed edits and ask "apply or skip?". Never
apply without a yes. If skipped, add `**CLAUDE.md update pending:** <one line>` to
the entry. If nothing qualifies, say nothing about it.

### 5. Confirm in one line

```
Logged: "<Project tag>: <Topic>" -> sessions.md
```

Append ` + CLAUDE.md updated` if drift edits were applied.
