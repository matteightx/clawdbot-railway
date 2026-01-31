# Moltbot Skills Creation Guide

**Read this before creating or modifying skills.**

This guide documents lessons learned from building skills for this deployment, mistakes made, and the correct workflow.

---

## Table of Contents

1. [Understanding Skills Architecture](#understanding-skills-architecture)
2. [Critical Mistakes We Made](#critical-mistakes-we-made)
3. [The Correct Workflow](#the-correct-workflow)
4. [SKILL.md Format Requirements](#skillmd-format-requirements)
5. [Deployment & Discovery](#deployment--discovery)
6. [Testing & Verification](#testing--verification)
7. [Troubleshooting Checklist](#troubleshooting-checklist)

---

## Understanding Skills Architecture

### Where Skills Live

**Three locations matter:**

```
1. Git Repo (source of truth)
   └── /skills/
       ├── fireflies/
       └── deep-work/

2. Railway Container (deployed code)
   └── /app/skills/              ← Git repo deployed here

3. Workspace (runtime)
   └── /root/clawd/skills/       ← Symlink to /data/workspace/skills/
       └── /data/workspace/skills/ ← Actual location (on volume)
```

### How Skills Are Discovered

**Loading precedence (highest to lowest):**
1. **Workspace skills** - `<workspace>/skills/` (e.g., `/root/clawd/skills/`)
2. **Managed skills** - `~/.clawdbot/skills/`
3. **Extra dirs** - via `skills.load.extraDirs` config
4. **Bundled skills** - Shipped with Moltbot

**Critical insight:** Skills are **snapshotted at session start**. Adding a skill mid-session won't make it appear until gateway restart.

### The Symlink Bridge

Our deployment uses a symlink to bridge workspace and volume:

```
/root/clawd/skills → /data/workspace/skills/
                            ↑
                     (persistent volume)
```

**Why:** Configured workspace is `/root/clawd/`, but skills must persist on volume (`/data/`). Symlink makes them visible to both.

---

## Critical Mistakes We Made

### ❌ Mistake 1: Malformed Metadata JSON

**What happened:**
```yaml
metadata: {"moltbot":{"requires":{"env":["FIREFLIES_API_KEY"],"primaryEnv":"FIREFLIES_API_KEY"}}
```
Missing closing `}` at the end.

**Impact:** Skill silently failed to load. No error, just absent from `<available_skills>`.

**Lesson:** Always validate JSON syntax. Use a JSON validator or `jq`:
```bash
echo '{"moltbot":{"requires":{"env":["KEY"]},"primaryEnv":"KEY"}}' | jq .
```

---

### ❌ Mistake 2: Skills in Wrong Location

**What happened:** Created skills in `/data/workspace/skills/`, but configured workspace was `/root/clawd/`. Moltbot looked in `/root/clawd/skills/` (didn't exist).

**Impact:** Skills existed on disk but weren't discoverable.

**Lesson:** Always check:
1. Where is the workspace? `moltbot config get agents.defaults.workspace`
2. Where are skills? `ls <workspace>/skills/`
3. Is there a symlink? `ls -la <workspace>/skills`

---

### ❌ Mistake 3: Lost Skills on Redeploy

**What happened:** Created skills directly in workspace via CLI. Railway redeployed → skills gone.

**Impact:** Lost hours of work (fireflies and deep-work skills).

**Root cause:** Skills weren't in git, so they existed only in ephemeral container storage.

**Lesson:** **Always commit skills to git immediately.** Never create skills only in runtime without backing up to git.

---

### ❌ Mistake 4: Lost Workspace Files (SOUL.md, USER.md)

**What happened:** Workspace bootstrap files disappeared after redeploy.

**Root cause:** Volume might have been recreated, or startup script had issues.

**Lesson:**
- Always back up workspace files to git (`workspace-template/`)
- Use automated backups (`/data/workspace-backups/`)
- Never trust ephemeral storage

---

### ❌ Mistake 5: Not Understanding Session Snapshots

**What happened:** Added skills, checked `<available_skills>`, didn't see them.

**Root cause:** Skills are loaded at session start. Mid-session additions aren't visible until restart.

**Lesson:** After adding skills, **always restart gateway**: `moltbot gateway restart`

---

## The Correct Workflow

### For Creating a New Skill

**Step 1: Create skill in git repo (locally)**

```bash
# In your local clawdbot-railway repo
cd skills/
mkdir my-new-skill
cd my-new-skill
```

**Step 2: Create SKILL.md**

```bash
cat > SKILL.md << 'EOF'
---
name: my-new-skill
description: Brief description of what this skill does
metadata: {"moltbot":{"requires":{"env":["MY_API_KEY"]},"primaryEnv":"MY_API_KEY"}}
---

# My New Skill

Detailed instructions for the agent on how to use this skill.

## Usage

```bash
# Example command
./scripts/my-script.sh arg1 arg2
```

## When to Use

Describe scenarios where this skill should be invoked.
EOF
```

**Step 3: Validate metadata JSON**

```bash
# Extract and validate JSON
grep "metadata:" SKILL.md | sed 's/metadata: //' | jq .

# If it outputs formatted JSON, you're good
# If it errors, fix your JSON
```

**Step 4: Create supporting files (if needed)**

```bash
mkdir scripts
cat > scripts/my-script.sh << 'EOF'
#!/usr/bin/env bash
# Your script here
EOF

chmod +x scripts/my-script.sh
```

**Step 5: Commit to git IMMEDIATELY**

```bash
cd ../../  # Back to repo root
git add skills/my-new-skill
git commit -m "Add my-new-skill for [purpose]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin main
```

**Step 6: Railway auto-deploys**

Watch Railway logs for deployment. Takes ~1-2 minutes.

**Step 7: Verify deployment**

In Slack/WebChat, ask Geoffrey:
```
"Check if my-new-skill exists in /app/skills/ and /root/clawd/skills/"
```

Expected output:
```
✓ /app/skills/my-new-skill/SKILL.md exists
✓ /root/clawd/skills/my-new-skill -> /data/workspace/skills/my-new-skill (symlink)
```

**Step 8: Set required environment variables**

If skill has `requires.env`, set in Railway:
```bash
railway variables set MY_API_KEY=actual_key_here
railway restart
```

**Step 9: Restart gateway & verify**

Ask Geoffrey:
```
"Restart your gateway and tell me what skills you have"
```

Should see `my-new-skill` in the list.

---

### For Modifying an Existing Skill

**Step 1: Edit locally**

```bash
cd skills/fireflies/
# Edit SKILL.md or scripts
```

**Step 2: Test metadata JSON (if changed)**

```bash
grep "metadata:" SKILL.md | sed 's/metadata: //' | jq .
```

**Step 3: Commit immediately**

```bash
git add skills/fireflies/
git commit -m "Update fireflies skill: [what changed]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin main
```

**Step 4: Railway redeploys automatically**

**Step 5: Restart gateway**

Ask Geoffrey: `"Restart gateway"`

**Step 6: Verify changes**

Ask Geoffrey to describe the skill or use it.

---

## SKILL.md Format Requirements

### Minimal Valid Format

```yaml
---
name: skill-name
description: What this skill does
---

# Skill Name

Instructions for the agent.
```

### With Metadata (Gating)

```yaml
---
name: skill-name
description: What this skill does
metadata: {"moltbot":{"requires":{"env":["API_KEY"],"bins":["curl"]},"primaryEnv":"API_KEY"}}
---

# Skill Name

Instructions.
```

### Metadata Fields Reference

**All metadata must be single-line JSON:**

```json
{
  "moltbot": {
    "requires": {
      "env": ["VAR1", "VAR2"],           // Required env vars (skill filtered out if missing)
      "bins": ["binary1", "binary2"],    // Required binaries on PATH
      "anyBins": ["opt1", "opt2"],       // At least one binary required
      "config": ["path.to.config"]       // Config path must be truthy
    },
    "primaryEnv": "API_KEY",             // Main env var (for UI display)
    "emoji": "🔥",                       // Optional emoji for UI
    "homepage": "https://...",           // Optional homepage URL
    "always": true,                      // Skip all gating checks (always load)
    "os": ["darwin", "linux"]            // Only load on these OSes
  }
}
```

### Common Mistakes

**❌ Wrong:**
```yaml
metadata: {"moltbot":{"requires":{"env":["KEY"],"primaryEnv":"KEY"}}
#                                                                  ^ missing }
```

**❌ Wrong:**
```yaml
metadata:
  {"moltbot": {
    "requires": {"env": ["KEY"]}
  }}
# Multi-line JSON not supported
```

**✅ Correct:**
```yaml
metadata: {"moltbot":{"requires":{"env":["KEY"]},"primaryEnv":"KEY"}}
```

---

## Deployment & Discovery

### Startup Script Flow

Our `startup.sh` does this on every Railway deployment:

```
1. Check if /data/ volume is mounted
2. Create /data/workspace/ if missing
3. Backup existing workspace files to /data/workspace-backups/
4. Sync git skills: /app/skills/* → /data/workspace/skills/
5. Create symlink: /root/clawd/skills → /data/workspace/skills/
6. Restore workspace template from git (if workspace empty)
7. Start Moltbot Gateway
```

### What This Means

- ✅ Git skills automatically deployed
- ✅ Skills persist on volume (survive redeploys)
- ✅ Workspace files backed up automatically
- ✅ Symlink created automatically
- ❌ Skills still require gateway restart to be discovered

### Environment Variables

**Required for deployment:**
- `CLAWDBOT_WORKSPACE` - Set to `/root/clawd` (or via Railway config)
- `PORT` - Railway sets this automatically

**Required for skill gating:**
- Any env vars listed in skill `requires.env`
- Example: `FIREFLIES_API_KEY`, `GHL_API_KEY`, etc.

Set via Railway:
```bash
railway variables set VAR_NAME=value
railway restart
```

---

## Testing & Verification

### After Adding a Skill

**1. Check git repo:**
```bash
ls skills/my-skill/
git log --oneline -1  # Should show your commit
```

**2. Check Railway deployed it:**

Ask Geoffrey:
```
"Check if /app/skills/my-skill/ exists"
```

**3. Check symlink worked:**

Ask Geoffrey:
```
"Check if /root/clawd/skills/my-skill exists and where it points"
```

Expected:
```
/root/clawd/skills/my-skill -> /data/workspace/skills/my-skill
```

**4. Check skill is loaded:**

Ask Geoffrey:
```
"What skills do you have? Specifically look for my-skill"
```

**5. Test the skill:**

Ask Geoffrey to use it:
```
"Use my-skill to [do something]"
```

### If Skill Doesn't Show Up

See [Troubleshooting Checklist](#troubleshooting-checklist) below.

---

## Troubleshooting Checklist

### Skill Not Appearing in `<available_skills>`

**Check 1: Is it in git?**
```bash
ls skills/my-skill/
```
- ❌ Missing → Create it and commit
- ✅ Exists → Continue

**Check 2: Did Railway deploy it?**

Ask Geoffrey: `"Check /app/skills/my-skill/"`
- ❌ Missing → Check Railway logs, may have failed to deploy
- ✅ Exists → Continue

**Check 3: Is symlink working?**

Ask Geoffrey: `"ls -la /root/clawd/skills/"`
- ❌ No symlink → Startup script failed, check logs
- ❌ Broken symlink → Restart Railway
- ✅ Symlink exists → Continue

**Check 4: Is metadata valid?**

Ask Geoffrey: `"Read /root/clawd/skills/my-skill/SKILL.md and validate the metadata JSON"`
- ❌ Invalid JSON → Fix and recommit
- ✅ Valid → Continue

**Check 5: Are requirements met?**

If skill has `requires.env`:
```bash
railway variables get | grep MY_API_KEY
```
- ❌ Missing → Set it: `railway variables set MY_API_KEY=value`
- ✅ Set → Continue

If skill has `requires.bins`:

Ask Geoffrey: `"which curl"` (or whatever binary)
- ❌ Not found → Install in container (add to startup script)
- ✅ Found → Continue

**Check 6: Did you restart gateway?**

Ask Geoffrey: `"When did you last restart?"`

If more than 5 minutes ago:
```
"Restart your gateway now"
```

After restart, ask: `"What skills do you have?"`

**Check 7: Session snapshot issue?**

If added mid-session, skills won't appear until new session.

Solution: Start a new conversation thread or DM.

---

### Skill Shows Up But Doesn't Work

**Check script permissions:**

Ask Geoffrey:
```
"Check permissions of /root/clawd/skills/my-skill/scripts/*"
```

Should be executable (`-rwxr-xr-x`).

If not:
```
"Make all scripts in my-skill executable"
```

**Check script errors:**

Ask Geoffrey to run the script directly:
```
"Run /root/clawd/skills/my-skill/scripts/test.sh with bash -x for debugging"
```

Look for errors in output.

**Check environment variables:**

Ask Geoffrey:
```
"Echo the value of MY_API_KEY (mask it if sensitive)"
```

If empty, set in Railway.

---

### Workspace Files Disappeared

**Check backups:**

Ask Geoffrey:
```
"List backups in /data/workspace-backups/"
```

**Restore from backup:**
```
"Copy the most recent backup to /root/clawd/"
```

**Prevent future loss:**

Ensure `workspace-template/` exists in git:
```bash
mkdir -p workspace-template
# Copy your SOUL.md, USER.md, etc. here
git add workspace-template/
git commit -m "Add workspace template backup"
git push
```

---

## Quick Reference Commands

### Check Skill Status
```bash
# Local (your machine)
ls skills/my-skill/
git log skills/my-skill/

# Railway (ask Geoffrey)
"Check /app/skills/my-skill/"
"Check /root/clawd/skills/my-skill"
"What skills do you have?"
```

### Deploy a Skill
```bash
# Local
git add skills/my-skill/
git commit -m "Add my-skill"
git push

# Railway auto-deploys
# Then restart gateway via Geoffrey:
"Restart gateway"
```

### Test Metadata JSON
```bash
# Local
grep "metadata:" skills/my-skill/SKILL.md | sed 's/metadata: //' | jq .

# Via Geoffrey
"Validate the metadata JSON in /root/clawd/skills/my-skill/SKILL.md"
```

### Set Environment Variable
```bash
# Local
railway variables set MY_VAR=value
railway restart

# Via Geoffrey
"Restart gateway after Railway redeploys"
```

---

## Best Practices

### ✅ Do This

1. **Commit skills to git immediately** after creating them
2. **Validate metadata JSON** before committing
3. **Set required env vars** in Railway before expecting skill to load
4. **Restart gateway** after adding/modifying skills
5. **Test skills** thoroughly after deployment
6. **Back up workspace files** to `workspace-template/` in git
7. **Use descriptive commit messages** explaining what the skill does
8. **Add Co-Authored-By** tag to commits
9. **Create skills in `skills/` directory** of git repo, not runtime
10. **Check Railway logs** if deployment seems to fail

### ❌ Don't Do This

1. **Don't create skills only in runtime** without committing to git
2. **Don't use multi-line JSON** in metadata
3. **Don't forget to close all braces** in metadata JSON
4. **Don't expect skills to appear mid-session** without restart
5. **Don't skip testing** after deployment
6. **Don't ignore Railway logs** when things break
7. **Don't put secrets in SKILL.md** (use env vars)
8. **Don't modify skills directly on Railway** (edit locally, commit, push)
9. **Don't assume volume persists forever** (always have git backup)
10. **Don't skip validation steps** in this guide

---

## Summary

**The Golden Rule:** Skills in git → Skills survive. Skills not in git → Skills disappear.

**The Workflow:**
1. Create skill locally in `skills/`
2. Validate metadata JSON
3. Commit to git immediately
4. Push to GitHub
5. Railway auto-deploys
6. Set required env vars
7. Restart gateway
8. Verify skill appears
9. Test skill works

**When in doubt:**
- Check this guide
- Ask Geoffrey to verify each step
- Look at Railway logs
- Test metadata JSON syntax
- Restart the gateway

---

**Last Updated:** 2026-01-31
**For:** clawdbot-railway deployment on Railway
**Workspace:** `/root/clawd/` (symlinked to `/data/workspace/`)
**Git Repo:** `https://github.com/matteightx/clawdbot-railway`
