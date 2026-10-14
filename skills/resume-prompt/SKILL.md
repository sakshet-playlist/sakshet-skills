---
name: resume-prompt
description: >
  Build a clean resume prompt for the work in this session (or a named project) from Sakshet's
  logged session history (sessions.md, handoff docs, project CLAUDE.md, memory), push the
  workspace-sync repo, and send the prompt to Sakshet's own Slack DM with a heading and context
  block so he can resume on either Mac. Use when Sakshet says "resume prompt", "give me a prompt
  to resume", "send me the resume prompt", "DM me the prompt", "/resume-prompt", or accepts the
  offer at the end of log-session.
---

# Resume Prompt

Goal: one Slack DM that lets a fresh Claude Code session resume cleanly, with nothing re-derived and
nothing settled reopened.

## Files

- Session log: `/Users/sakshet.chavan/Workspace/Claude Projects/sessions.md` (newest first)
- Handoffs: `Claude Projects/<project>/<topic>-handoff-YYYY-MM-DD.md`
- Project CLAUDE.md: `Claude Projects/<project>/CLAUDE.md` (if it exists)
- Memory index: `/Users/sakshet.chavan/.claude/projects/-Users-sakshet-chavan-Workspace/memory/MEMORY.md`
- Sync scripts: `~/workspace-sync-pull.sh`, `~/workspace-sync-push.sh` (repo `~/Workspace`, branch `main`)
- Slack self-DM: channel_id `U043M1TC7RD` (resolves to D0441FLLPSP)

## Steps

### 1. Identify the project and pull

- Project = the one this session worked on. If unclear or the user names another, use that. If still
  ambiguous, ask one question.
- Run `~/workspace-sync-pull.sh` so parallel sessions from the other Mac are visible.

### 2. Gather sources (read, don't skim titles)

1. `sessions.md`: this session's entry plus every entry for the same project from the last 3 days.
   **Same-day parallel sessions matter most**: their open items and decisions can change the next steps.
   If this session isn't logged yet, say so and offer to run log-session first.
2. Every handoff in the project folder modified in the last 3 days (`ls -t`). Read the newest fully.
3. Project CLAUDE.md: settled decisions, IDs, "never say" rules.
4. MEMORY.md: pick the 1-3 memory files relevant to the project. Read them to check they don't contradict
   the handoffs. If they do, flag it in the message.
5. Uncommitted changes: `git -C ~/Workspace status --short`.

Build only from what these sources say. Do not invent open items, send status, or approvals.

### 3. Reconcile before writing

- If a parallel session settled, superseded or took over something this session left open, update the
  next steps (e.g. "15 Oct reply is owned by X, we supply input").
- If a handoff doesn't mention a parallel session's handoff, add a short "Parallel sessions" pointer to
  the newest handoff of this session.
- Pending items Sakshet must decide (CLAUDE.md apply/skip, open DDCs) go under "Waiting on me".

### 4. Push

Run `~/workspace-sync-push.sh` (or `git add` the project files and commit/push to `main` with the
attribution line). Record the short commit hash for the header. If the push fails, say so and put
"not pushed" in the header instead of a hash.

### 5. Compose the DM

Slack markdown, under 5,000 characters. If it would be longer, shorten the context and keep the prompt.
No em dashes anywhere (scan before sending). Terse, Sakshet's voice.

````
# Resume: <project short name>: <topic> (<YYYY-MM-DD>)

**Project:** <tag> | **Sessions:** <ids> | **Repo:** workspace-sync `<hash>` on main

**Where it stands**
- 3-5 bullets: what's done/decided, with Notion/ADO IDs

**Not sent yet**
- Every drafted-but-unsent Slack/email/comment, with draft IDs

**Waiting on me**
- Decisions only Sakshet can make

**Prompt to paste into Claude Code** (from `~/Workspace/Claude Projects/<project>`)

```
Resume <work> (sessions <ids>, <date>).

Run ~/workspace-sync-pull.sh, then read in order:
1. Claude Projects/<project>/CLAUDE.md
2. <newest handoff> (<what's in it>)
3. <parallel handoffs> (<what's in it>)
4. <PRD/doc + Notion id, "re-fetch first" for Notion>
5. Memory: <relevant memory files>

Settled, don't reopen: <decisions + verified numbers>.

Check first: <MCP connections needed, e.g. snowflake-exec-reader; external state to check, e.g. incident channel>. Tell me if a connection is down before doing anything that needs it.

Then:
1. <next action, concrete, with IDs/ts>
2. ...

Rules: no em dashes, concise, show every Slack draft before saving, verify live, show arithmetic, flag contradictions with earlier sessions as explicit corrections, mark anything unverified.
```
````

Prompt rules:
- The read order is explicit file paths, newest handoff first after CLAUDE.md.
- "Settled, don't reopen" lists only what the sources mark as decided or live-verified.
- Next actions are numbered, each concrete enough to start without asking. Anything that sends,
  posts or edits outside the session says "show me first".
- Mark unverified items as unverified.

### 6. Send

Send directly with `slack_send_message` to channel_id `U043M1TC7RD` (self-DM only, pre-authorized).
Never send this skill's output to anyone else. Then reply in chat with:

```
Sent resume prompt -> <message link> (repo <hash>)
```

Plus one line for anything flagged in step 3 (contradictions, unlogged session, push failure).
