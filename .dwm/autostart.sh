#!/bin/bash

dwm_alsa () {
    VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
    echo "VOL $VOL%"
}

dwm_backlight () {
    echo "BL $(xbacklight -get)%"
}

dwm_battery () {
    CHARGE=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)
    if [ "$STATUS" == "Not charging" ]; then
        echo "BAT ${CHARGE}%"
    else
        echo "BAT ${CHARGE}% [$STATUS]"
    fi
}

dwm_network () {
    SSID=$(iwctl station wlan0 show | awk '/Connected network/{print $3}')
    echo "NET [$SSID]"
}

while true; do
   xsetroot -name "| $(dwm_network) | $(dwm_alsa) | $(dwm_backlight) | $(dwm_battery) | $(date +"%R") "
   sleep 1s
done &


fcitx5 &
feh --recursive --randomize --bg-fill ~/Pictures/壁纸/1.jpg &
picom --experimental-backends --config ~/.dwm/picom/picom.conf