#!/bin/sh
pgrep -x "dwmblocks" > /dev/null || (nohup dwmblocks > /dev/null 2>&1 &)
exec dwm

