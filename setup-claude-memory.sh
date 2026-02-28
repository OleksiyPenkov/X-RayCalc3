#!/usr/bin/env bash
# Copies .claude/memory/MEMORY.md to Claude Code's auto-memory location
# Run from the project root on any machine after cloning

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/.claude/memory/MEMORY.md"

if [ ! -f "$SOURCE" ]; then
  echo "ERROR: $SOURCE not found"
  exit 1
fi

# Get the absolute project path and convert to Claude Code's hash format
# D:\Foo\Bar  ->  D--Foo-Bar
# /home/user/foo  ->  -home-user-foo
PROJECT_PATH="$(cd "$SCRIPT_DIR" && pwd -W 2>/dev/null || pwd)"
HASH=$(echo "$PROJECT_PATH" | sed 's/[:\\/]/-/g')

TARGET_DIR="$HOME/.claude/projects/$HASH/memory"
mkdir -p "$TARGET_DIR"
cp "$SOURCE" "$TARGET_DIR/MEMORY.md"

echo "Copied memories to: $TARGET_DIR/MEMORY.md"
