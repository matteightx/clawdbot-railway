#!/bin/bash
set -e

echo "=== Moltbot Startup ==="

# Support both workspace locations
VOLUME_WORKSPACE="/data/workspace"
CONFIGURED_WORKSPACE="${CLAWDBOT_WORKSPACE:-/root/clawd}"

# Check if volume is mounted
if [ ! -d /data ]; then
  echo "ERROR: /data volume not mounted!"
  exit 1
fi

# Ensure both workspaces exist
mkdir -p "$VOLUME_WORKSPACE"
mkdir -p "$CONFIGURED_WORKSPACE"

echo "Volume workspace: $VOLUME_WORKSPACE"
echo "Configured workspace: $CONFIGURED_WORKSPACE"

# Check if bootstrap files exist in either location
has_bootstrap_files=false
if [ -f "$CONFIGURED_WORKSPACE/SOUL.md" ] || [ -f "$CONFIGURED_WORKSPACE/USER.md" ]; then
  has_bootstrap_files=true
  echo "Workspace bootstrap files exist in $CONFIGURED_WORKSPACE ✓"
elif [ -f "$VOLUME_WORKSPACE/SOUL.md" ] || [ -f "$VOLUME_WORKSPACE/USER.md" ]; then
  has_bootstrap_files=true
  echo "Workspace bootstrap files exist in $VOLUME_WORKSPACE ✓"
else
  echo "No bootstrap files found - workspace may be new"
fi

# Backup existing workspace files to /data/workspace-backups/ before doing anything
if [ "$has_bootstrap_files" = true ]; then
  backup_dir="/data/workspace-backups/$(date +%Y%m%d-%H%M%S)"
  echo "Creating backup at $backup_dir"
  mkdir -p "$backup_dir"
  cp "$CONFIGURED_WORKSPACE"/*.md "$backup_dir/" 2>/dev/null || true
  cp "$VOLUME_WORKSPACE"/*.md "$backup_dir/" 2>/dev/null || true
  echo "Backup created ✓"
fi

# Ensure skills directory exists on volume
mkdir -p "$VOLUME_WORKSPACE/skills"

# Sync skills from git repo to volume workspace
# This ONLY touches the skills/ directory, NOT the bootstrap files
if [ -d /app/skills ]; then
  echo "Syncing skills from /app/skills to $VOLUME_WORKSPACE/skills..."

  for skill_dir in /app/skills/*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      echo "  - $skill_name"

      # Copy skill, overwriting existing
      cp -r "$skill_dir" "$VOLUME_WORKSPACE/skills/"
    fi
  done

  # Make scripts executable
  chmod +x "$VOLUME_WORKSPACE/skills"/*/scripts/*.sh 2>/dev/null || true

  echo "Skills synced to volume ✓"
fi

# Create symlink from configured workspace to volume skills
# This makes skills visible to Moltbot even if workspace paths differ
if [ "$CONFIGURED_WORKSPACE" != "$VOLUME_WORKSPACE" ]; then
  echo "Creating symlink: $CONFIGURED_WORKSPACE/skills -> $VOLUME_WORKSPACE/skills"

  # Remove existing skills directory or symlink
  rm -rf "$CONFIGURED_WORKSPACE/skills"

  # Create symlink
  ln -s "$VOLUME_WORKSPACE/skills" "$CONFIGURED_WORKSPACE/skills"

  echo "Symlink created ✓"
fi

# If workspace template exists in git, restore it (ONLY if workspace is empty)
if [ "$has_bootstrap_files" = false ] && [ -d /app/workspace-template ]; then
  echo "Restoring workspace template from git..."
  cp -n /app/workspace-template/*.md "$CONFIGURED_WORKSPACE/" 2>/dev/null || true
  echo "Template restored ✓"
fi

# List what's in workspaces now
echo ""
echo "=== Configured Workspace ($CONFIGURED_WORKSPACE) ==="
ls -lh "$CONFIGURED_WORKSPACE"/*.md 2>/dev/null || echo "  (no .md files)"
echo ""
echo "=== Skills (via symlink) ==="
ls -d "$CONFIGURED_WORKSPACE/skills"/*/ 2>/dev/null || echo "  (no skills)"
echo ""
echo "=== Volume Workspace ($VOLUME_WORKSPACE) ==="
ls -lh "$VOLUME_WORKSPACE"/*.md 2>/dev/null || echo "  (no .md files)"
echo ""

# Start Moltbot Gateway
echo "Starting Moltbot Gateway..."
exec moltbot gateway --port "${PORT:-18789}" --verbose
