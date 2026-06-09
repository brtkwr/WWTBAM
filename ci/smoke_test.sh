#!/usr/bin/env bash
# CI smoke test: boot the original WWTBAM.EXE headless in DOSBox and check
# that it actually draws the title screen (the spotlight logo), rather than
# crashing or sitting on a black screen.
set -euo pipefail

WORK=$(mktemp -d)
trap 'pkill dosbox || true; pkill Xvfb || true; rm -rf "$WORK"' EXIT

unzip -q WWTBAM.DAT -d "$WORK/c"

cat > "$WORK/dosbox.conf" <<EOF
[sdl]
output=surface
[autoexec]
mount c $WORK/c
c:
WWTBAM.EXE
EOF

Xvfb :99 -screen 0 1024x768x24 &
sleep 2
DISPLAY=:99 dosbox -conf "$WORK/dosbox.conf" &> "$WORK/dosbox.log" &

# wait for the DOSBox window
WIN=""
for _ in $(seq 1 30); do
  WIN=$(DISPLAY=:99 xdotool search --name "DOSBox" 2>/dev/null | head -1 || true)
  [ -n "$WIN" ] && break
  sleep 1
done
if [ -z "$WIN" ]; then
  echo "FAIL: DOSBox window never appeared"
  cat "$WORK/dosbox.log"
  exit 1
fi

# give the intro time to start drawing the rings, then grab the screen
sleep 12
DISPLAY=:99 import -window "$WIN" "$WORK/shot.png"

# the title screen is colourful: demand a reasonable number of distinct
# colours and plenty of non-black pixels
COLORS=$(convert "$WORK/shot.png" -format %k info:)
NONBLACK=$(convert "$WORK/shot.png" -fill white +opaque black -format "%[fx:int(mean*w*h)]" info:)
echo "distinct colours: $COLORS, non-black pixels: $NONBLACK"

if [ "$COLORS" -lt 3 ] || [ "$NONBLACK" -lt 5000 ]; then
  echo "FAIL: title screen did not render"
  exit 1
fi
echo "ok: game boots and draws the title screen"
