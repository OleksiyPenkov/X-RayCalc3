#!/bin/bash
# deploy.sh — Stage all X-Ray Calc 3 artifacts into deploy/ for InnoSetup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy"
STORAGE_DIR="/d/SoftwareStorage/X-RayCalc3"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

err=0

check_file() {
  if [ ! -e "$1" ]; then
    echo -e "${RED}MISSING:${NC} $1"
    err=1
  fi
}

check_dir() {
  if [ ! -d "$1" ]; then
    echo -e "${RED}MISSING DIR:${NC} $1"
    err=1
  fi
}

echo "=== X-Ray Calc 3 Deploy ==="
echo ""

# --- Validate sources ---
echo "Checking source files..."

check_file "$PROJECT_DIR/OUT/BIN/XRayCalc3.exe"
check_file "$PROJECT_DIR/OUT/BIN/XRayCalc3.x64.exe"
check_file "$PROJECT_DIR/XRCXPreview/Release/Win32/XRCPreviewHandlerLib.dll"
check_file "$PROJECT_DIR/XRCXPreview/Release/Win64/XRCPreviewHandlerLib.dll"
check_file "$PROJECT_DIR/OUT/BIN/Help/UserManual.html"
check_dir  "$PROJECT_DIR/OUT/BIN/Help/images"
check_file "$PROJECT_DIR/Assets/XRayCalc3_Icon.ico"
check_dir  "$STORAGE_DIR/Henke"
check_dir  "$STORAGE_DIR/Jobs"

if [ "$err" -ne 0 ]; then
  echo ""
  echo -e "${RED}Validation failed. Fix missing files before deploying.${NC}"
  exit 1
fi

echo -e "${GREEN}All sources found.${NC}"
echo ""

# --- Clean and create staging directory ---
if [ -d "$DEPLOY_DIR" ]; then
  echo "Cleaning previous deploy/..."
  rm -rf "$DEPLOY_DIR"
fi

mkdir -p "$DEPLOY_DIR/Win32"
mkdir -p "$DEPLOY_DIR/Win64"
mkdir -p "$DEPLOY_DIR/Henke"
mkdir -p "$DEPLOY_DIR/Examples"
mkdir -p "$DEPLOY_DIR/Help/images"

# --- Copy files ---
echo "Copying executables..."
cp "$PROJECT_DIR/OUT/BIN/XRayCalc3.exe"     "$DEPLOY_DIR/Win32/"
cp "$PROJECT_DIR/OUT/BIN/XRayCalc3.x64.exe" "$DEPLOY_DIR/Win64/"

echo "Copying preview handler DLLs..."
cp "$PROJECT_DIR/XRCXPreview/Release/Win32/XRCPreviewHandlerLib.dll" "$DEPLOY_DIR/Win32/"
cp "$PROJECT_DIR/XRCXPreview/Release/Win64/XRCPreviewHandlerLib.dll" "$DEPLOY_DIR/Win64/"

echo "Copying icon..."
cp "$PROJECT_DIR/Assets/XRayCalc3_Icon.ico" "$DEPLOY_DIR/"

echo "Copying Henke data..."
cp "$STORAGE_DIR/Henke/"*.bin "$DEPLOY_DIR/Henke/"
henke_count=$(ls -1 "$DEPLOY_DIR/Henke/"*.bin 2>/dev/null | wc -l)
echo "  $henke_count .bin files"

echo "Copying examples..."
cp "$STORAGE_DIR/Jobs/"*.xrcx "$DEPLOY_DIR/Examples/"
example_count=$(ls -1 "$DEPLOY_DIR/Examples/"*.xrcx 2>/dev/null | wc -l)
echo "  $example_count .xrcx files"

echo "Copying help files..."
cp "$PROJECT_DIR/OUT/BIN/Help/UserManual.html" "$DEPLOY_DIR/Help/"
cp "$PROJECT_DIR/OUT/BIN/Help/images/"*        "$DEPLOY_DIR/Help/images/"

# --- Summary ---
echo ""
echo -e "${GREEN}=== Deploy complete ===${NC}"
echo ""
echo "Staged to: $DEPLOY_DIR"
echo ""
echo "Contents:"
echo "  Win32/XRayCalc3.exe"
echo "  Win32/XRCPreviewHandlerLib.dll"
echo "  Win64/XRayCalc3.x64.exe"
echo "  Win64/XRCPreviewHandlerLib.dll"
echo "  Henke/              ($henke_count files)"
echo "  Examples/           ($example_count files)"
echo "  Help/UserManual.html + images/"
echo "  XRayCalc3_Icon.ico"
echo ""

total_size=$(du -sh "$DEPLOY_DIR" | cut -f1)
echo "Total size: $total_size"
echo ""
echo "Next: run InnoSetup on XRayCalc3Setup.iss"
