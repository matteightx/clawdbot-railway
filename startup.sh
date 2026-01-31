#!/bin/bash
set -e

echo "=== Moltbot Startup ==="

WORKSPACE="/data/workspace"

# Check if volume is mounted
if [ ! -d /data ]; then
  echo "ERROR: /data volume not mounted!"
  exit 1
fi

# Create workspace if it doesn't exist
if [ ! -d "$WORKSPACE" ]; then
  echo "Creating new workspace at $WORKSPACE"
  mkdir -p "$WORKSPACE"
fi

# Check if workspace has bootstrap files
has_bootstrap_files=false
if [ -f "$WORKSPACE/SOUL.md" ] || [ -f "$WORKSPACE/USER.md" ] || [ -f "$WORKSPACE/AGENTS.md" ]; then
  has_bootstrap_files=true
  echo "Workspace bootstrap files exist ✓"
else
  echo "No bootstrap files found - workspace may be new"
fi

# Backup existing workspace files to /data/workspace-backups/ before doing anything
if [ "$has_bootstrap_files" = true ]; then
  backup_dir="/data/workspace-backups/$(date +%Y%m%d-%H%M%S)"
  echo "Creating backup at $backup_dir"
  mkdir -p "$backup_dir"
  cp -r "$WORKSPACE"/*.md "$backup_dir/" 2>/dev/null || true
  echo "Backup created ✓"
fi

# Ensure skills directory exists
mkdir -p "$WORKSPACE/skills"

# Sync skills from git repo to workspace
# This ONLY touches the skills/ directory, NOT the bootstrap files
if [ -d /app/skills ]; then
  echo "Syncing skills from /app/skills to $WORKSPACE/skills..."

  for skill_dir in /app/skills/*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      echo "  - $skill_name"

      # Copy skill, overwriting existing
      cp -r "$skill_dir" "$WORKSPACE/skills/"
    fi
  done

  # Make scripts executable
  chmod +x "$WORKSPACE/skills"/*/scripts/*.sh 2>/dev/null || true

  echo "Skills synced ✓"
fi

# If workspace template exists in git, restore it (ONLY if workspace is empty)
if [ "$has_bootstrap_files" = false ] && [ -d /app/workspace-template ]; then
  echo "Restoring workspace template from git..."
  cp -n /app/workspace-template/*.md "$WORKSPACE/" 2>/dev/null || true
  echo "Template restored ✓"
fi

# List what's in workspace now
echo ""
echo "Workspace contents:"
ls -lh "$WORKSPACE"/*.md 2>/dev/null || echo "  (no .md files)"
echo ""
ls -d "$WORKSPACE/skills"/*/ 2>/dev/null || echo "  (no skills)"
echo ""

# Start Moltbot Gateway
echo "Starting Moltbot Gateway..."
exec moltbot gateway --port "${PORT:-18789}" --verbose
