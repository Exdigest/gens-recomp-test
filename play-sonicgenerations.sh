#!/usr/bin/env bash
# Linux launcher for the "Sonic Generations Recomp" Windows build.
# Put this script in the SAME folder as sonicgenerations.exe, then run it.
#
# What it does (same as the original "play sonicgenerations.cmd"):
#   - sets REX_HEAL_DISCOVER=1 and REX_GPU_PLUGIN=xenos
#   - runs the exe through Proton (via umu-launcher) so D3D12 -> Vulkan (vkd3d-proton)
#
# You must supply your own game files: default.xex + everything next to it,
# placed in ./assets  (see "Getting the game files" in the instructions).

set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cd "$HERE"

[ -f sonicgenerations.exe ] || { echo "sonicgenerations.exe not found next to this script." >&2; exit 1; }

# Game data lookup order matches the exe: assets, game, data, own folder
found=""
for d in assets game data .; do
  [ -f "$d/default.xex" ] && { found="$d"; break; }
done
if [ -z "$found" ]; then
  echo "default.xex not found in ./assets (or ./game, ./data)." >&2
  echo "Copy your game files there, or extract them with:" >&2
  echo "    python3 extract.py /path/to/your/game.iso ./assets" >&2
  exit 1
fi

# Game data root as a Windows path (Proton exposes Linux "/" as drive Z:)
ROOT_LINUX="$(readlink -f "$found")"
ROOT_WIN="Z:${ROOT_LINUX//\//\\}"

export REX_HEAL_DISCOVER="${REX_HEAL_DISCOVER:-1}"   # tolerant dispatcher
export REX_GPU_PLUGIN="${REX_GPU_PLUGIN:-xenos}"     # without this nothing renders

# Separate Wine prefix, kept out of the game folder
export WINEPREFIX="${WINEPREFIX:-$HOME/.local/share/sonicgenerations-prefix}"
export PROTONPATH="${PROTONPATH:-$HOME/.local/share/Steam/steamapps/common/Proton - Experimental}"          # or a path to proton-cachyos
export GAMEID="${GAMEID:-umu-0}"
export PROTON_ENABLE_WAYLAND="${PROTON_ENABLE_WAYLAND:-0}"
mkdir -p "$WINEPREFIX"

if command -v umu-run >/dev/null 2>&1; then
  exec umu-run ./sonicgenerations.exe "--game_data_root=$ROOT_WIN" "$@"
fi

echo "umu-run not found; falling back to plain Wine (D3D12 support is much weaker)." >&2
echo "Recommended: install umu-launcher and re-run." >&2
command -v wine >/dev/null 2>&1 || { echo "wine not installed either." >&2; exit 1; }
exec wine ./sonicgenerations.exe "--game_data_root=$ROOT_WIN" "$@"
