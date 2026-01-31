---
name: fireflies
description: Search and retrieve Fireflies.ai call transcripts and summaries. Use when asked about past calls, meetings, conversations with specific people or companies. Handles relative time queries like "last week", "two weeks ago", "a month ago".
metadata: {"moltbot":{"requires":{"env":["FIREFLIES_API_KEY"],"primaryEnv":"FIREFLIES_API_KEY"}}
---

# Fireflies

Retrieve call transcripts and summaries from Fireflies.ai.

## Usage

```bash
# Search by participant name
/data/workspace/skills/fireflies/scripts/fireflies.sh search "Alex"

# Search by company
/data/workspace/skills/fireflies/scripts/fireflies.sh search "Opascope"

# Search with time filter
/data/workspace/skills/fireflies/scripts/fireflies.sh search "Uday" --from "2026-01-18" --to "2026-01-24"

# Get recent calls (last 7 days)
/data/workspace/skills/fireflies/scripts/fireflies.sh recent

# Get specific transcript by ID
/data/workspace/skills/fireflies/scripts/fireflies.sh get <transcript_id>

# Get transcript summary
/data/workspace/skills/fireflies/scripts/fireflies.sh summary <transcript_id>
```

## Time Interpretation

When user asks about time periods, calculate dates as follows:

| User says | Meaning | Example (if today is Jan 30, 2026 Thursday) |
|-----------|---------|---------------------------------------------|
| "last week" | Week ending last Friday | Jan 18-24 (Sat-Fri) |
| "two weeks ago" | Week ending two Fridays ago ±5 days | Jan 6-17 |
| "a month ago" | 3-6 weeks ago | Dec 19 - Jan 9 |
| "yesterday" | Previous day | Jan 29 |
| "this week" | Current week so far | Jan 25-30 |

**Important:** "Last week" means the COMPLETED week, not the past 7 days.

See `references/date-handling.md` for detailed date calculation logic.

## Workflow

1. Parse the user's request for:
   - Person/company name to search
   - Time period (interpret relative dates)
2. Run the search script with appropriate filters
3. If multiple results, list them with dates and participants
4. If user wants details, fetch the full transcript/summary

## Response Format

When listing calls:
```
📞 **Calls with [Name]**

1. **[Title]** - Jan 23, 2026 (45 min)
   Participants: Alex, Matt, Sarah

2. **[Title]** - Jan 18, 2026 (30 min)
   Participants: Alex, Jordan
```

When showing transcript, include:
- Call title and date
- Participants
- Duration
- Summary (overview, action items, key points)
- Full transcript if requested
