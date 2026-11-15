#DIT WAS ECHT KANKER TE DOEN
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cd "$HERE"

say() { echo -e "\n==> $*"; }
die() { echo "error: $*" >&2; exit 1; }

[ -f sonicgenerations.exe ]        || die "sonicgenerations.exe not found. Run this inside the extracted game folder."
[ -f play-sonicgenerations.sh ]    || die "play-sonicgenerations.sh must be in this folder too."
chmod +x play-sonicgenerations.sh

# 1. Proton runner
say "Checking for umu-launcher (runs the game through Proton)..."
if ! command -v umu-run >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm umu-launcher \
    || { command -v paru >/dev/null && paru -S --needed umu-launcher; } \
    || { command -v yay  >/dev/null && yay  -S --needed umu-launcher; } \
    || die "Couldn't install umu-launcher. Install it manually (AUR: umu-launcher) and re-run."
fi

# KANKER DING
normalize_assets() {
  [ -d assets ] || return 0
  [ -f assets/default.xex ] && return 0
  local x d
  x="$(find assets -iname 'default.xex' -print -quit)"
  [ -n "$x" ] || return 0
  d="$(dirname "$x")"
  if [ "$d" != "assets" ]; then
    shopt -s dotglob
    mv "$d"/* assets/
    shopt -u dotglob
  fi
  [ -f assets/default.xex ] || mv "assets/$(basename "$x")" assets/default.xex
}

# 2. Game files
normalize_assets
if [ ! -f assets/default.xex ]; then
  say "Game files needed (you must supply your own copy)."
  SRC=""
  if command -v zenity >/dev/null 2>&1; then
    SRC="$(zenity --file-selection --title='Pick your game ISO / package / default.xex' 2>/dev/null || true)"
  elif command -v kdialog >/dev/null 2>&1; then
    SRC="$(kdialog --getopenfilename "$HOME" 2>/dev/null || true)"
  fi
  if [ -z "$SRC" ]; then
    read -r -p "Path to your game ISO / GoD / XBLA package / extracted folder: " SRC
  fi
  SRC="${SRC/#\~/$HOME}"
  [ -e "$SRC" ] || die "Not found: $SRC"
  mkdir -p assets
  if [ -d "$SRC" ] && [ -f "$SRC/default.xex" ]; then
    cp -r "$SRC"/. assets/
  elif [ "$(basename "$SRC")" = "default.xex" ]; then
    cp -r "$(dirname "$SRC")"/. assets/
  else
    command -v python3 >/dev/null || die "python3 is needed to extract game files."
    python3 extract.py "$SRC" "$HERE/assets"
  fi
  normalize_assets
  [ -f assets/default.xex ] || die "default.xex still missing in ./assets after import."
fi
say "Game files OK."

# 3. Shortcuts
say "Creating shortcuts..."
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
mkdir -p "$APPS" "$DESKTOP_DIR"
ENTRY="$APPS/sonicgenerations.desktop"

cat > "$ENTRY" <<EOF
[Desktop Entry]
Type=Application
Name=Sonic Generations
Comment=Sonic Generations Recomp (via Proton)
Exec=/bin/bash -c '"$HERE/play-sonicgenerations.sh" >> "$HERE/launch.log" 2>&1'
Path=$HERE
Icon=$HERE/cover.png
Terminal=false
Categories=Game;
EOF
chmod +x "$ENTRY"
cp "$ENTRY" "$DESKTOP_DIR/Sonic Generations.desktop"
chmod +x "$DESKTOP_DIR/Sonic Generations.desktop"
# GNOME needs the desktop file marked as trusted; harmless elsewhere if you even dig through this code
gio set "$DESKTOP_DIR/Sonic Generations.desktop" metadata::trusted true 2>/dev/null || true
update-desktop-database "$APPS" 2>/dev/null || true

say "Done. Double-click 'Sonic Generations' on your desktop or find it in the app menu."
echo "First launch downloads Proton and builds the Wine prefix, so give it a minute or two."
echo "If something goes wrong, check: $HERE/launch.log"
