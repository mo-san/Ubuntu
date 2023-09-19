# this supposes the internal display name to be "LVDS-1" and the external one "HDMI-1"

if DISPLAY=:0 xrandr | grep HDMI-1 | grep -iP -q "(?<!dis)connected"
then # if connected
	DISPLAY=:0 xrandr --output HDMI-1 --auto --primary --output LVDS-1 --off
	# redraw conky
	pkill conky
	conky -d --display=:0 --quiet
fi
