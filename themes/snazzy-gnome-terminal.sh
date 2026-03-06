#!/usr/bin/env bash
# =============================================================================
#  Apply Snazzy color scheme to GNOME Terminal
#  Snazzy: https://github.com/sindresorhus/iterm2-snazzy
# =============================================================================
set -euo pipefail

if ! command -v gsettings &>/dev/null; then
  echo "[ERR] gsettings not found — this script requires GNOME Terminal."
  exit 1
fi

PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
BASE="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE}/"

echo "[INFO] Applying Snazzy to GNOME Terminal profile: ${PROFILE}"

gsettings set "$BASE" use-theme-colors false
gsettings set "$BASE" use-theme-transparency false

# Snazzy palette (ANSI 0-15)
PALETTE="['#282A36','#FF5C57','#5AF78E','#F3F99D','#57C7FF','#FF6AC1','#9AEDFE','#F1F1F0',
          '#686868','#FF5C57','#5AF78E','#F3F99D','#57C7FF','#FF6AC1','#9AEDFE','#EFF0EB']"
gsettings set "$BASE" palette "$PALETTE"

gsettings set "$BASE" background-color '#282A36'
gsettings set "$BASE" foreground-color '#EFF0EB'
gsettings set "$BASE" bold-color       '#EFF0EB'
gsettings set "$BASE" bold-color-same-as-fg true
gsettings set "$BASE" cursor-background-color '#97979B'
gsettings set "$BASE" cursor-foreground-color '#282A36'
gsettings set "$BASE" cursor-colors-set true
gsettings set "$BASE" highlight-background-color '#41455A'
gsettings set "$BASE" highlight-foreground-color '#EFF0EB'
gsettings set "$BASE" highlight-colors-set true
gsettings set "$BASE" font 'MesloLGS NF 13'
gsettings set "$BASE" use-system-font false

echo "[OK]  Snazzy applied. Reopen GNOME Terminal to see the effect."
