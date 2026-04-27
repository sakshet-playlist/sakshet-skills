---
name: slack-triage
description: Exhaustive Slack triage sweep. Finds every unanswered mention, open thread, unreads, and pending follow-throughs across all channels (public, private, DMs, group DMs). Reads full threads, not snippets. Produces paginated P0–P5 priority list in chat (not Slack DM). Trigger: "run triage", "what did I miss", "show me everything", "deep sweep", or requests to check mentions/threads/unreads. Uses slack_search_public_and_private, slack_read_channel, slack_read_thread. Requires Slack MCP connection.
---

# Slack Exhaustive Triage (Deep Sweep)

## Overview

This skill performs a COMPREHENSIVE, EXHAUSTIVE sweep of the user's Slack workspace
to surface EVERY thread, DM, unreads, unseen message, and open question where action
is expected but not yet taken. It captures the complete context of each thread by reading
in full (not from snippets), then classifies items into 6 priority tiers (P0–P5).

Output is PAGINATED and displayed in Claude chat (not sent to Slack) for user review.

---

## Required: Know the user's Slack identity

Before running, confirm the user's Slack user ID. For Sakshet Chavan it is `U043M1TC7RD`.
If running for a different user, ask them for their Slack user ID first (they can find
it in Slack: click their profile photo → View profile → More → Copy member ID).

---

## CRITICAL GUARDRAILS

These are non-negotiable. Failing any of these means the triage is incomplete.

### G1 — Pagination Discipline
- **EVERY search must be paginated to exhaustion.** If `next_cursor` exists, you MUST call it.
- Do NOT stop at page 1 or assume 20 results is the complete set.
- Count total results per search and confirm you've retrieved all of them.
- Track: "Search A yielded 47 results across 3 pages" etc.

### G2 — Full Thread Reading
- **NEVER classify a thread from search snippet alone.**
- Call `slack_read_thread` on EVERY unique (channel_id, message_ts) pair.
- Read the ENTIRE thread, including all replies.
- If a thread has 100+ messages, paginate within the thread.
- Snippets are deceptive — the full context always changes classification.

### G3 — Complete Channel Coverage
- **You must reach EVERY channel and DM that surfaces in searches.**
- For every DM/group DM found, call `slack_read_channel` with a 7-day window.
- Do NOT assume private channels are "less important."
- Include archived channels if user is a member.

### G4 — No False Negatives on Follow-Throughs
- **Catch EVERY commitment the user made that is not visibly complete.**
- Look for: "will", "I'll", "can you", "I'll send", "let me check", "I'll review", "by EOD", "by tomorrow", "agreed"
- Mark as FOLLOW-THROUGH if visible evidence of completion is not in the thread.
- If unsure, classify as FOLLOW-THROUGH (err on the side of surfacing).

### G5 — Timestamp Accuracy
- **All dates and times must be accurate to the current session date.**
- Use consistent date format (YYYY-MM-DD).
- Mark carry-overs with original date.
- Never assume "yesterday" — calculate based on today's date.

### G6 — State Verification
- **Before outputting, verify the state of every item:**
  - Thread still unresolved? (re-read the last 3 messages to confirm)
  - Someone waiting on user? (check for follow-up tags/pings)
  - Deadline approaching? (calculate time to deadline)
  - User's last response? (confirm sender ID = user ID)

---

## STEP 1 — Comprehensive Mention Sweep (Last 48 Hours)

Run these FIVE searches using `slack_search_public_and_private` with exhaustive pagination:

**Search A: Direct mentions in past 48 hours**
```
query: <@USER_ID> after:YESTERDAY_DATE
sort: timestamp desc
limit: 20
Paginate ALL results to completion
```

**Search B: Direct replies to user in past 48 hours**
```
query: to:<@USER_ID> after:YESTERDAY_DATE
sort: timestamp desc
limit: 20
Paginate ALL results to completion
```

**Search C: Threads user started or replied to in past 48 hours**
```
query: from:<@USER_ID> after:YESTERDAY_DATE
sort: timestamp desc
limit: 20
Paginate ALL results to completion
```

**Search D: Unreads and thread participation (expanded)**
```
query: <@USER_ID> is:thread after:YESTERDAY_DATE
sort: timestamp desc
limit: 20
Paginate ALL results to completion
```

**Search E: Unread messages (if API supports)**
```
query: <@USER_ID> after:YESTERDAY_DATE has:pin OR has:bookmark
sort: timestamp desc
limit: 20
Paginate ALL results to completion
```

After each search, document:
- Total results found
- Number of pages paginated
- Unique thread count
- Any patterns (e.g., which channels are most active)

Collect all unique `(channel_id, message_ts)` pairs. Deduplicate.

---

## STEP 2 — Extended Unanswered Thread Sweep (Beyond 48 Hours)

Run these FOUR searches to catch older open threads:

**Search F: Mentions before 48-hour window**
```
query: <@USER_ID> before:YESTERDAY_DATE
sort: timestamp desc
limit: 20
Paginate UP TO 5 pages (100 results minimum)
```

**Search G: Direct replies before 48-hour window**
```
query: to:<@USER_ID> before:YESTERDAY_DATE
sort: timestamp desc
limit: 20
Paginate UP TO 5 pages (100 results minimum)
```

**Search H: Threads with no recent activity (stale threads)**
```
query: <@USER_ID> is:thread before:2_WEEKS_AGO
sort: timestamp desc
limit: 20
Paginate UP TO 3 pages
```

**Search I: User's own threads where others replied**
```
query: from:<@USER_ID> before:YESTERDAY_DATE is:thread
sort: timestamp desc
limit: 20
Paginate UP TO 3 pages
Check for replies AFTER user's last message
```

Mark all these as CARRIED OVER with original date.

---

## STEP 3 — Private Channel and DM Deep Dive

For every DM or private channel that surfaced in Steps 1–2:

**Call `slack_read_channel` for each DM/group DM:**
```
channel_id: [DM_ID or GROUP_DM_ID]
oldest: UNIX_TIMESTAMP_7_DAYS_AGO
limit: 50 (not 20 — more volume in DMs)
response_format: detailed
Paginate if next_cursor exists
```

This ensures NO private messages are missed that might not surface in search.
DMs are the highest-signal, highest-priority channel — never skip.

---

## STEP 4 — Read Every Thread in Full

For EVERY unique thread from Steps 1–3, call `slack_read_thread`:

```
channel_id: [CHANNEL_ID]
message_ts: [PARENT_MESSAGE_TS]
limit: 100 (not 20 — threads can be long)
response_format: detailed
Paginate through entire thread if > 100 messages
```

For each thread, answer these questions in detail:

**a) What was the last message in the thread?**
- Exact text
- Sender name and ID
- Timestamp

**b) Did the user send the last message, or someone else?**
- If user: is there a reply AFTER the user's message?
- If someone else: what is the content?

**c) If someone else sent the last message, did they:**
- Tag the user? (check for `<@USER_ID>` in message)
- Ask a direct question? (ends with `?`, uses "can you", "could you", "please")
- Expect a response? (context suggests response is required)
- Express urgency? (words like "asap", "today", "urgent", "blocked", "waiting")

**d) If the user sent the last message, did anyone reply after with:**
- A question? (needs answer)
- A follow-up? (needs acknowledgement)
- A decision? (user needs to acknowledge)
- Additional context? (user needs to review)

**e) Did the user commit to an action that is NOT visibly complete?**
- Look for: "will", "I'll", "let me", "can", "I'll check", "I'll send", "I'll review"
- Evidence of completion: follow-up message from user OR visible deliverable in thread
- If no completion visible and no follow-up, flag as FOLLOW-THROUGH

### Classification (Detailed)

| Label | Condition | Example |
|---|---|---|
| **NEEDS IMMEDIATE REPLY** | Open question to user, urgent tag, blocking others, user hasn't replied | "Sakshet, can you approve this by EOD?" (unanswered) |
| **NEEDS FOLLOW-THROUGH** | User committed to action (explicit or implicit) that isn't visibly done | User: "I'll review" → no follow-up message, no document shared |
| **NEEDS ACKNOWLEDGEMENT** | Someone is waiting for user to acknowledge/confirm/agree | "Sounds good?" (user hasn't replied "yes") |
| **SOFT PENDING** | Older thread, not urgent, but open question exists | A question asked 2 weeks ago with no answer |
| **RESOLVED** | Clear closure: user replied, question answered, decision made | User: "Got it, I'll do X" → later: "Done" |
| **FYI ONLY** | User was cc'd, no response expected, informational | "FYI: Server maintenance" or "cc: team update" |

Discard RESOLVED from main output. Keep FYI ONLY for a small separate section.

---

## STEP 5 — Self-Check Before Output

Before producing output, confirm YES to ALL nine:

1. ✅ Did you paginate EVERY search to exhaustion (not just page 1)?
2. ✅ Did you read the ENTIRE thread content for every (channel_id, message_ts) pair?
3. ✅ Did you check all DMs and group DMs with a 7-day window read?
4. ✅ Did you catch every follow-through commitment the user made (explicit or implied)?
5. ✅ Did you identify every unanswered question in every thread?
6. ✅ Did you re-verify the CURRENT state of each thread before classifying?
7. ✅ Did you check for unreads, unseen messages, and thread subscriptions?
8. ✅ Did you search for older threads (beyond 48 hours) with explicit older-thread searches?
9. ✅ Is there any thread you found in search results that you did NOT read in full?

If ANY answer is NO, do not proceed. Go back and fix it.

---

## STEP 6 — Produce Prioritized Triage Output (Paginated)

### Priority Criteria

| Priority | Criteria | Timeline |
|---|---|---|
| 🔴 **P0 — Critical/NOW** | Legal/compliance decision, security, outage, someone explicitly blocked, user is explicitly asked for approval needed for release | Act within hours |
| 🔴 **P1 — Act Today** | Direct question to user, blocking others, time-sensitive decision, deadline today/tomorrow, someone explicitly waiting, code freeze/release-related | Act today |
| 🟠 **P2 — Act Today or Tomorrow** | Important but not blocking, reviews, promised follow-throughs, deadline this week | Act within 24-48 hours |
| 🟡 **P3 — This Week** | Medium priority, soft deadlines, awaiting decisions from others | Act within 3-5 days |
| 🟢 **P4 — Next Week / Soft Deadline** | Can wait, older carry-overs, low urgency, roadmap/planning items | Act next week |
| ⚪ **P5 — Backlog / FYI** | Very old threads, no response expected, informational, archived discussions | Reference only |

### Output Format (Per Priority Level)

For each priority level, output in this format:

```
*🔴 P0 — Critical/NOW* (N items)
_(Legal, compliance, blocking, explicit approval needed, release decisions)_

• *[Channel/DM]* — *[Who is asking]* | [One-line: what user needs to do right now]
  └─ Waiting: [Who is waiting? How long?]
  └─ Status: [Last message: "...quote..."]
  └─ Link: <[permalink]|Open thread>

[Repeat for each P0 item]

---

*🔴 P1 — Act Today* (N items)
...
```

### Pagination Strategy

- **P0, P1, P2 on first page.** (These are urgent.)
- **P3, P4 on second page.** (Can review separately.)
- **P5/FYI on final page.** (Reference only.)

Display each page clearly. Let user navigate page-by-page.

### Each Item Must Include

- **Channel/DM name** (bold)
- **Who is asking** (name, bold)
- **One-line action** (what the user must do)
- **Who is waiting** (if someone is blocked)
- **Last message** (first 50 chars of last message in thread, show sender)
- **Permalink** (Slack message link)
- **Days overdue** (if applicable; e.g., "asked 3 days ago, no response")

---

## STEP 7 — Output Display (NO Slack Send)

After completing the triage:

1. **Display P0 + P1 + P2 on Page 1 in chat** (paginated summary)
2. **Display P3 + P4 on Page 2** (if user asks for more)
3. **Display P5 + FYI on Page 3** (reference page)

After displaying, provide a summary:
```
✅ Triage Complete

Total threads analyzed: [N]
P0 items: [N] (critical)
P1 items: [N] (today)
P2 items: [N] (this week)
P3 items: [N] (softer)
P4 items: [N] (backlog)
P5 items: [N] (FYI)

Oldest unanswered thread: [date], [channel]
Most active channel: [channel name] ([N] items)

View Page 1 (critical) | View Page 2 (medium) | View Page 3 (reference)
```

**Do NOT send to Slack.** Output is for user review in Claude.

---

## Bonus Commands

After triage runs, the user may follow up with:

| User says | What to do |
|---|---|
| `draft reply for item [N]` | Draft a Slack reply for that numbered item |
| `page 2` / `page 3` | Display next page of results |
| `only P0` / `only P1` | Filter and re-display only that priority |
| `re-run` or `refresh` | Re-run the full sweep for latest updates |
| `details for item [N]` | Show full thread context for that item |
| `thread [link]` | Read a specific thread in full |

---

## Important Rules

- **No hardcoded channel list.** Cover EVERYTHING surfaced in search results.
- **Paginate EVERY search.** Never stop at 20 results if `next_cursor` exists.
- **Never classify a thread from snippet alone.** Read the full thread.
- **Threads where the user sent the last message are NOT automatically resolved.** Always check if someone replied after.
- **DMs are highest priority surface.** Never skip them or read fewer than 7 days of history.
- **Older unanswered threads (beyond 48 hrs) MUST appear.** Mark them CARRIED OVER with original date.
- **If a search returns 0 results, retry with broader terms.** Don't assume it means no activity.
- **Track what you've searched.** Avoid duplicate searches.
- **Be suspicious of "resolved" classification.** Verify with recent messages before labeling as closed.
