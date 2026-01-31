---
name: deep-work
description: Execute complex multi-step deliverables by gathering context, synthesizing information, and producing polished outputs. Discovers the right prompt structure based on the specific request rather than using templates.
---

# Deep Work

Multi-step workflow for creating deliverables from source material (calls, documents, meetings).

## When to Use

Requests involving creating work products:
- "Write a memo based on..."
- "Draft an email summarizing..."
- "Create a brief for..."
- "Put together a report from..."

## Workflow

### Step 1: Parse the Request

Extract from the user's message:

| Element | Extract |
|---------|---------|
| **Source** | What call/doc/meeting? When? |
| **Deliverable** | What format? (memo/email/brief/report) |
| **Audience** | Who reads it? What do they care about? |
| **Voice** | Who is writing? What's their role? |
| **Purpose** | Inform? Request? Update? Decide? |
| **Constraints** | Length? Tone? Deadline? |

### Step 2: Gather Source Material

**For calls:** Use Fireflies skill to fetch transcript
**For documents:** Read files or fetch URLs
**For meetings:** Get notes or recordings

### Step 3: Discover Prompt Structure

Ask these questions to build the right prompt:

**About the deliverable:**
- What format conventions does this type of document have?
- What structure would serve the audience best?
- What's the right length for this context?

**About the audience:**
- What's their relationship to the sender?
- What do they already know vs. need to learn?
- What decision or action do they need to take?
- What tone is appropriate? (formal/casual/technical)

**About the content:**
- What are the 3-5 most important points from the source?
- What specific data/quotes should be included?
- What's the main message or ask?
- What objections or questions might arise?

**About the voice:**
- How would this person naturally write?
- What's their typical communication style?
- What authority or credibility do they bring?

### Step 4: Build Execution Prompt

Construct a structured prompt with discovered elements:

```markdown
## Role & Voice
You are [specific role + context about the person writing].

## Situation
[Background: what led to this, relationships, prior context]

## Source Material
[Transcript/document/notes - the raw input]

## Audience Analysis
Who: [recipients + their role/priorities]
What they know: [existing context]
What they need: [information/decision/action]
How they'll read it: [skimming vs. deep reading]

## Deliverable Requirements
Format: [specific type]
Structure: [discovered best structure for this case]
Length: [appropriate for audience + purpose]
Tone: [discovered appropriate tone]

## Content Strategy
Main message: [the one thing they must take away]
Supporting points: [2-4 key points from source]
Specific evidence: [data/quotes to include]
Call to action: [what happens next]

## Execution Approach
1. [How to open - based on audience/purpose]
2. [How to structure the body]
3. [How to close - based on desired action]
4. [How to ensure key facts from source are included]

## Quality Checks
Before finalizing, verify:
- Main message clear in first [paragraph/section]
- Tone matches [discovered appropriate style]
- Key facts from source present
- Next steps explicit
- Length appropriate
```

### Step 5: Execute

Run the constructed prompt with source material. Do this in the current conversation.

### Step 6: Deliver

Present the output:
- Brief context ("Here's the [deliverable] based on [source]")
- The deliverable itself
- Offer iteration ("Want me to adjust tone/length/focus?")

## Key Principle

**No templates.** Every execution discovers:
1. What this specific audience needs
2. What this specific deliverable requires
3. What this specific source material provides
4. What this specific voice sounds like

The prompt structure emerges from the analysis, not from a template.

## Example Execution

**User:** "Write a memo to our lenders based on the call with Kenny last week about the Q3 situation"

**Step 1 - Parse:**
- Source: Call with Kenny, last week, Q3 topic
- Deliverable: Memo
- Audience: Lenders
- Voice: CFO (implied)
- Purpose: Update on situation

**Step 2 - Gather:**
```bash
fireflies.sh search "Kenny" --from 2024-01-15
fireflies.sh get abc123
```

**Step 3 - Discover:**
- Lenders need: confidence, transparency, specific numbers
- Memo format: formal header, situation/details/next steps
- Tone: professional, direct, solutions-oriented
- CFO voice: financial focus, action-oriented
- Key from transcript: Q3 metrics, challenges, recovery plan

**Step 4 - Build prompt with discovered elements**

**Step 5 - Execute with source attached**

**Step 6 - Deliver memo with offer to iterate**
