---
name: notion-large-update
description: |-
    Reliably write large or multi-section content to a Notion page when the Notion MCP server is hitting Cloudflare 403 blocks or timeouts. Use this skill when: you need to create or fully populate a Notion page with content longer than ~5KB, you've already tried a single replace_content/update_content call and got a Cloudflare 403 error page in the response, you need to write content with multiple tables, callouts, and sections (which trip the security rule more often), or the user asks to write a long PRD, audit, gate doc, or report to Notion. The skill creates the page with a minimal stub then appends sections one at a time using a sentinel marker pattern that survives Cloudflare's content filter.
---

# Notion Large-Update Skill

## Overview

The Notion MCP server is fronted by Cloudflare. Large or table-heavy `replace_content`
and `update_content` payloads often get blocked with a 403 HTML error page. Even when
the actual size limit isn't documented, payloads with multiple tables, nested callouts,
or many code blocks fail more frequently than plain markdown.

This skill writes long Notion pages reliably by chunking content using a sentinel
marker pattern.

---

## When to use

Trigger this skill when ANY of these are true:

- The user asks to create a Notion page longer than ~5KB.
- You already tried a `notion-update-page` call and got a Cloudflare 403 page in the
  response body.
- The content has more than 2 tables, OR more than 3 callouts, OR is structured into
  4+ distinct sections.
- The user asks to write a multi-section audit, PRD, gate doc, or report.

If the page is short and simple, use `notion-create-pages` or `notion-update-page`
directly — don't over-engineer.

---

## The Pattern

### Step 1 — Create the page with a minimal stub

Use `notion-create-pages` with ONLY:
- The frontmatter properties (title, status, etc.)
- An executive summary (2-3 paragraphs max)
- A single trailing sentinel callout that you'll replace in subsequent updates

Example stub content:

```
<callout icon="🎯" color="blue_bg">
    {scope/context block — 1-3 lines}
</callout>

<table_of_contents/>

# Executive Summary

{2-3 paragraph summary}

<callout icon="⏭️" color="gray_bg">
    Continuing content below.
</callout>
```

The trailing callout is the sentinel marker. Keep it short and unique.

### Step 2 — Append sections one at a time

For each section, use `notion-update-page` with command `update_content`:

- `old_str`: the EXACT current sentinel marker text (e.g., `Continuing content below.`)
- `new_str`: the new section content, ending with a fresh copy of the sentinel marker

Example section update:

```
old_str: "Continuing content below."
new_str: "# Section 1 — Title

{section body, ~1-3KB}

Continuing content below."
```

Repeat for each section. The marker shifts down with each update.

### Step 3 — Final section removes the marker

The last update replaces the marker with the final section content WITHOUT a trailing
marker. The page is now complete.

---

## Critical Rules

1. **Keep each chunk under ~3KB when possible.** Tables and code blocks count more than
   plain text against the Cloudflare filter.

2. **Avoid stacking multiple tables in one chunk.** If a section has 2+ tables, split it
   into multiple updates, one table per update.

3. **If a Cloudflare 403 hits, simplify the content.** Replace tables with bullet lists
   for that chunk. Tables can be added back in a later update once the page is built.

4. **If a "timeout" error occurs, the previous update may have actually succeeded.** ALWAYS
   call `notion-fetch` on the page before retrying — the marker may already be gone.

5. **Watch for indentation traps.** When content gets nested inside a callout (e.g., the
   trailing sentinel was inside a callout), all subsequent updates land inside that callout.
   This causes deep tab indentation in the page. To avoid: use a top-level paragraph as
   the sentinel marker, not text inside a callout.

6. **The sentinel marker must be unique on the page.** Don't use phrases like "below" or
   "continued" without a distinguishing prefix. `Continuing audit content below.` is good;
   `Continuing.` is not.

---

## Recipe Template

Pseudocode for a typical run:

```
1. Plan the section breakdown:
   - List sections in order
   - Estimate chunk size per section
   - Identify sections that need to be split (tables, large code blocks)

2. Create page stub:
   notion-create-pages with exec summary + sentinel marker

3. For each section in order:
   notion-update-page command=update_content
     old_str = current sentinel
     new_str = section content + new sentinel

   if Cloudflare 403:
     - simplify content (drop tables, shorten)
     - retry with smaller payload
   if timeout:
     - notion-fetch the page
     - check if the section was actually added
     - if yes, move to next section
     - if no, retry

4. Final section:
   notion-update-page command=update_content
     old_str = current sentinel
     new_str = final section content (no trailing sentinel)

5. Verify with notion-fetch:
   - confirm all sections are present
   - confirm no orphaned sentinel markers
```

---

## What NOT to do

- Don't try to fit everything into one giant `replace_content` call. It will fail.
- Don't use `replace_content` after the page has child pages or databases — it will
  delete them. Use `update_content` with markers instead.
- Don't skip the `notion-fetch` verification step at the end. Indentation issues are
  invisible in tool responses but visible to the user.
- Don't add the `[Claudey Creates]` suffix in this skill's logic — that's a separate
  global preference applied to the page title at creation time.

---

## Example Session Reference

This pattern was developed during the 2026-04-30 Booker Partner API Surface Audit
session. The audit is ~15KB of structured content with multiple tables and callouts —
representative of the case this skill was built for.

Notion page: search "Booker Partner API Surface Audit" in the Booker Document Storage
data source for an example of a successfully-built large page.
