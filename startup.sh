#!/bin/bash
set -e

echo "=== Moltbot Startup ==="

# Ensure workspace exists
mkdir -p /data/workspace/skills

# Copy skills from git repo to workspace
# This syncs git-backed skills to the volume workspace
if [ -d /app/skills ]; then
  echo "Syncing skills from /app/skills to /data/workspace/skills..."

  # Copy each skill from git to workspace (preserves workspace-only skills)
  for skill_dir in /app/skills/*/; do
    skill_name=$(basename "$skill_dir")
    echo "  - $skill_name"
    cp -r "$skill_dir" "/data/workspace/skills/"
  done

  # Make scripts executable
  chmod +x /data/workspace/skills/*/scripts/*.sh 2>/dev/null || true

  echo "Skills synced ✓"
else
  echo "No /app/skills directory found"
fi

# Start Moltbot Gateway
echo "Starting Moltbot Gateway..."
exec moltbot gateway --port "${PORT:-18789}" --verbose
