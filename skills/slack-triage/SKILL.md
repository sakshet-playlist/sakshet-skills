---
name: slack-triage
description: >
  Run a full Slack triage sweep to find all unanswered mentions, open threads,
  and pending follow-throughs across ALL channels (public, private, DMs, group DMs).
  Produces a prioritized action list (P1/P2/P3) and sends it as a Slack DM to the user.

  ALWAYS use this skill when the user says any of the following:
  - "run triage", "morning triage", "slack triage"
  - "what did I miss on Slack", "what's pending on Slack"
  - "find unanswered Slack threads", "where haven't I replied"
  - "show me my Slack priorities", "sweep my Slack"
  - "catch me up on Slack", "what needs my attention on Slack"

  Also trigger when the user asks Claude to check their Slack mentions, open threads,
  or unanswered messages — even if they don't use the word "triage".

  The skill uses Slack MCP tools: slack_search_public_and_private, slack_read_channel,
  slack_read_thread, slack_send_message. It must be connected to Slack MCP to function.
---

# Slack Morning Triage

## Overview

This skill performs a comprehensive sweep of the user's Slack workspace to surface
every thread where they have been tagged, asked a question, or are expected to respond
— and haven't yet. It then classifies items by priority and sends a formatted DM to
the user on Slack.

---

## Required: Know the user's Slack identity

Before running, confirm the user's Slack user ID. For Sakshet Chavan it is `U043M1TC7RD`.
If running for a different user, ask them for their Slack user ID first (they can find
it in Slack: click their profile photo → View profile → More → Copy member ID).

---

## STEP 1 — Mention sweep (last 48 hours, high priority window)

Run these three searches using `slack_search_public_and_private`.
- `sort`: timestamp desc
- `limit`: 20
- Paginate every cursor until fully exhausted — never stop at page 1.

```
Search A: <@USER_ID> after:YESTERDAY_DATE
Search B: to:<@USER_ID> after:YESTERDAY_DATE
Search C: from:<@USER_ID> after:YESTERDAY_DATE
```

Search C catches threads the user started or replied to so you can check if
someone replied after them.

Collect all unique `thread_parent_ts` + `channel_id` pairs. Deduplicate across searches.

---

## STEP 2 — Older unanswered thread sweep (beyond 48 hours)

Paginate up to 3 pages each:

```
Search D: <@USER_ID> before:YESTERDAY_DATE
Search E: to:<@USER_ID> before:YESTERDAY_DATE
```

Focus on threads that look open from the snippet (question in snippet, no resolution
visible). Collect unique thread references. Mark these as CARRIED OVER.

---

## STEP 3 — DM and group DM sweep

For every DM or group DM channel that surfaced in Steps 1–2:
- Call `slack_read_channel` with `oldest` = Unix timestamp for 7 days ago
- `limit`: 20, `response_format`: concise

This ensures no private DMs are missed that might not surface in search.

---

## STEP 4 — Read every open thread in full

For every unique thread from Steps 1–3, call `slack_read_thread`
(`response_format`: concise). For each thread determine:

**a)** What was the last message?
**b)** Did the user send the last message, or someone else?
**c)** If someone else — did they tag the user, ask a direct question, or expect a response?
**d)** If the user sent the last message — did anyone reply after with a follow-up
   that needs acknowledgement?
**e)** Did the user commit to an action ("will check", "I'll share", "will review",
   "I'll update by EOD") that has not visibly been completed?

### Classification

| Label | Meaning |
|---|---|
| **NEEDS REPLY** | Open question or tag directed at user, no reply from user after it |
| **FOLLOW-THROUGH** | User committed to an action not yet done |
| **RESOLVED** | Thread is closed, no action needed |
| **FYI ONLY** | User was cc'd for awareness, no response expected |

Discard RESOLVED from the main output. Keep FYI ONLY in a short separate section.

---

## STEP 5 — Self-check before responding

Before producing output, confirm YES to all five:

1. Did you paginate ALL search results — not just page 1?
2. Did you read every open thread in full — not just from the search snippet?
3. Did you check all DMs and group DMs that surfaced?
4. Did you catch every follow-through commitment the user made?
5. Is nothing missed?

Only proceed after all five are YES.

---

## STEP 6 — Produce the prioritized triage list

### Priority criteria

| Priority | Criteria |
|---|---|
| 🔴 **P1 — Act Today** | Direct question to user, blocking others, time-sensitive decision, legal/compliance/release topic, someone is waiting to proceed |
| 🟠 **P2 — Act Today or Tomorrow Morning** | Important but not blocking, async reviews, promised follow-throughs |
| 🟡 **P3 — Watch / Low Urgency** | Older carry-overs, soft deadlines, FYI threads worth staying aware of |

### Output format

Format in Slack markdown (*bold*, _italic_, bullet points, `<url|text>` links).

```
*🗓 Daily Slack Triage — [TODAY'S DATE]*

*🔴 P1 — Act Today*
_(Direct questions, blocking others, time-sensitive, legal/release/compliance)_

• *[Channel/DM]* — *[Who is asking]* | [One-line: what user needs to do]
  → <[permalink]|Open thread>

*🟠 P2 — Act Today or Tomorrow Morning*
_(Important but not blocking, reviews, promised follow-throughs)_

• *[Channel/DM]* — *[Who]* | [One-line summary]
  → <[permalink]|Open thread>

*🟡 P3 — Watch / Low Urgency*
_(Older carry-overs, soft deadlines, awareness)_

• *[Channel/DM]* — *[Who]* | [One-line summary] _(CARRIED OVER from [date])_
  → <[permalink]|Open thread>

*👁 FYI Only — No Reply Needed*
• *[Channel/DM]* — [One-line summary]

---
_Triage complete · [TODAY'S DATE]_
```

---

## STEP 7 — Send as a Slack DM to the user

Call `slack_send_message` with:
- `channel_id`: the user's Slack user ID (DMs to self)
- `message`: the full formatted output from Step 6

After sending, confirm to the user:
> "✅ Done — your triage has been sent as a Slack DM. Want me to draft replies for any P1 items?"

---

## Bonus commands

After triage runs, the user may follow up with:

| User says | What to do |
|---|---|
| `draft reply for item [N]` | Draft a Slack reply for that numbered item |
| `only P1s` | Re-run triage but surface P1 items only |
| `re-run` or `refresh` | Re-run the full sweep for latest updates |
| `what's new since this morning` | Search for new mentions since the triage ran |
| `mark [item] done` | Acknowledge and note it as resolved |

---

## Important rules

- **No hardcoded channel list.** Cover everything surfaced in search results.
- **Paginate every search.** Never stop at 20 results if a next cursor exists.
- **Never classify a thread as resolved without reading it in full.**
- **Threads where the user sent the last message are NOT automatically resolved** —
  always check if someone replied after.
- **DMs are highest priority surface.** Never skip them.
- **Older unanswered threads (beyond 48 hrs) must appear** — mark them CARRIED OVER
  with the original date.
