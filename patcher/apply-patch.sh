#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Privyr CRM – Bricks Builder Form Support Patcher
#
# Patches the Privyr CRM Integration plugin to forward
# Bricks Builder form submissions (via the "Custom" action)
# to the Privyr webhook API.
#
# Usage:
#   ./apply-patch.sh [path/to/privyr-crm-integration]
#
# If no path is given, defaults to ../privy-crm-integration
# relative to the script's location.
#
# Idempotent — safe to run multiple times.
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="${1:-"$SCRIPT_DIR/../privy-crm-integration"}"

# Validate
if [[ ! -f "$PLUGIN_DIR/includes/class-privyr-crm.php" ]]; then
  echo "✖ Privyr CRM plugin not found at: $PLUGIN_DIR"
  echo "  Pass the plugin directory as the first argument."
  exit 1
fi

CONSTANTS_FILE="$PLUGIN_DIR/includes/class-privyr-crm-constants.php"
INTEGRATION_DIR="$PLUGIN_DIR/includes/integrations"
INTEGRATION_FILE="$INTEGRATION_DIR/class-privyr-bricks-form.php"
ICON_DIR="$PLUGIN_DIR/admin/images/plugins"
ICON_FILE="$ICON_DIR/bricks-logo.svg"

MARKER="bricks_form"
ALREADY_PATCHED=false

if grep -q "$MARKER" "$CONSTANTS_FILE" 2>/dev/null; then
  ALREADY_PATCHED=true
fi

if $ALREADY_PATCHED; then
  echo "● Already patched — skipping."
  exit 0
fi

echo "▸ Patching Privyr CRM for Bricks Builder support…"

# 1. Copy files
echo "  ✓ Copying integration file"
cp "$SCRIPT_DIR/class-privyr-bricks-form.php" "$INTEGRATION_FILE"

echo "  ✓ Copying Bricks logo icon"
mkdir -p "$ICON_DIR"
cp "$SCRIPT_DIR/bricks-logo.svg" "$ICON_FILE"

# 2. Apply patches
echo "  ✓ Applying code patches"
patch -d "$PLUGIN_DIR" -p1 < "$SCRIPT_DIR/class-privyr-crm-constants.patch" >/dev/null
patch -d "$PLUGIN_DIR" -p1 < "$SCRIPT_DIR/class-privyr-crm.patch" >/dev/null

echo "✔ Patch applied successfully."
echo ""
echo "  Bricks forms must have \"Custom\" selected as an action"
echo "  in the Bricks form element settings for leads to be"
echo "  forwarded to Privyr."
