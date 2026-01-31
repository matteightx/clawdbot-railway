# Date Handling for Fireflies Queries

## The User's Mental Model

When users say "last week," they mean the **completed business week** — not the past 7 days.

Their week runs **Saturday to Friday** (or sometimes Monday to Sunday). "Last week" means the week that's already fully over.

## Date Calculation Rules

Given today's date, calculate the following:

### "Last week"
The completed week ending on the most recent Friday (or the Friday before if today is Sat/Sun).

**Example:** Today is Thursday, Jan 30, 2026
- Most recent Friday = Jan 24, 2026
- "Last week" = **Jan 18 (Sat) to Jan 24 (Fri)**

### "Two weeks ago"
The week before "last week," with ±5 day flexibility.

**Example:** Today is Thursday, Jan 30, 2026
- Two Fridays ago = Jan 17, 2026
- "Two weeks ago" ≈ **Jan 6 to Jan 17** (with some flexibility)

### "A month ago"
Roughly 3-6 weeks in the past. Cast a wider net.

**Example:** Today is Thursday, Jan 30, 2026
- "A month ago" ≈ **Dec 19, 2025 to Jan 9, 2026**

### "This week"
Current week so far, from the most recent Saturday to today.

**Example:** Today is Thursday, Jan 30, 2026
- "This week" = **Jan 25 (Sat) to Jan 30 (today)**

### "Yesterday"
Literal previous day.

### "Last month" / "In December"
The entire calendar month referenced.

## Bash Date Calculation

```bash
# Get last Friday
last_friday=$(date -d "last friday" +%Y-%m-%d)

# Get Saturday before last Friday (start of "last week")
last_week_start=$(date -d "$last_friday - 6 days" +%Y-%m-%d)

# Two weeks ago range
two_weeks_end=$(date -d "$last_friday - 7 days" +%Y-%m-%d)
two_weeks_start=$(date -d "$two_weeks_end - 11 days" +%Y-%m-%d)

# A month ago range
month_ago_end=$(date -d "3 weeks ago" +%Y-%m-%d)
month_ago_start=$(date -d "6 weeks ago" +%Y-%m-%d)
```

## When in Doubt

If the time reference is ambiguous:
1. Cast a **wider net** (more days) rather than narrower
2. Ask for clarification if results are many/few
3. Show the date range you searched so user can correct

## Examples

| User says | Today | Search from | Search to | Note |
|-----------|-------|-------------|-----------|------|
| "last week" | Jan 30 (Thu) | Jan 18 (Sat) | Jan 24 (Fri) | Completed week |
| "this week" | Jan 30 (Thu) | Jan 25 (Sat) | Jan 30 (today) | Current week so far |
| "two weeks ago" | Jan 30 (Thu) | Jan 6 | Jan 17 | Week before last |
| "a month ago" | Jan 30 (Thu) | Dec 19 | Jan 9 | 3-6 weeks back |
| "yesterday" | Jan 30 (Thu) | Jan 29 | Jan 29 | Literal day |
| "call with Alex last Friday" | Jan 30 (Thu) | Jan 24 | Jan 24 | Specific day |
