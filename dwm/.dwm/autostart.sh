#!/bin/sh

# 1. FORCE SYSTEM PATHS (The Critical Fix)
# We manually add /usr/bin, /bin, etc. so 'date' and 'awk' work immediately.
# 5. WALLPAPER & EXTRAS
# (Uncomment what you use)
# feh --bg-fill /path/to/wallpaper.jpg &
(sleep 2 && zsh -c "setsid dwmblocks > /dev/null 2>&1 &") &

nitrogen --restore &
setsid -f ~/.local/bin/bt-monitor.sh &
setxkbmap -option ctrl:swapcaps &
# Start tmux server on login so continuum can restore sessions
tmux start-server &


