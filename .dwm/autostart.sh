#!/bin/bash

alsa () {
    VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
    if [ $VOL -gt 0 ]; then
        echo "󰕾 [$VOL%]"
    elif [ $VOL -eq 0 ]; then
        echo "󰖁 "
    fi
}

backlight () {
    GET=$(xbacklight -get)
    echo "󰖨 [$GET%]"
}

battery () {
    CHARGE=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)
    if [ "$STATUS" == "Not charging" ]; then
        echo "󱟢 [$CHARGE%]"
    elif [ "$STATUS" == "Full" ]; then
        echo "󱟢 [$CHARGE%]"
    elif [ "$STATUS" == "Discharging" ]; then
        echo "󱟤 [$CHARGE%]"
    elif [ "$STATUS" == "Charging" ]; then
        echo "󱟦 [$CHARGE%]"
    fi
}

network () {
    SSID=$(iwctl station wlan0 show | awk '/Connected network/{print $3}')
    if [ "$SSID" == "" ]; then
        echo "󰤭 "
    elif [ "$SSID" != "" ]; then
        echo "󰤨 [$SSID]"
    fi
}

cpu () {
    VALUE=$(top -b -n1 | sed -n 's/.*,\s*\([0-9]*\)\.[0-9]* id.*/\1/p')
    GET=$((100 - $VALUE))
    echo "󰍛 [$GET%]"
}

men () {
    GET=$(free -m | grep "内存" | awk '{printf "%d", ($3)/$2*100}')
    echo "󰍜 [$GET%]"
}

while true; do
   xsetroot -name "$(network) $(backlight) $(alsa) $(cpu) $(men) $(battery) 󰥔 [$(date +"%R")]"
   sleep 1s
done &

fcitx5 &
feh --recursive --randomize --bg-fill ~/Pictures/壁纸/2.jpg &
picom --config ~/.dwm/picom/picom.conf &
xset dpms 0 0 0