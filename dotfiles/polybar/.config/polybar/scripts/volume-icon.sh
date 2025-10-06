# ~/.config/polybar/scripts/volume-icon.sh
#!/usr/bin/env bash
vol=$(pamixer --get-volume 2>/dev/null || pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' 'NR==1{gsub(/ /,""); print $2+0}')
mute=$(pamixer --get-mute 2>/dev/null || pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
if [[ "$mute" == "true" || "$mute" == "yes" ]]; then
  echo ""
  exit 0
fi
if ((vol >= 66)); then echo ""
elif ((vol >= 33)); then echo ""
elif ((vol > 0)); then echo ""
else echo ""
fi
