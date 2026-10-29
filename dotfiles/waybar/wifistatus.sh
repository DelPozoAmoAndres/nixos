ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
if [ -n "$ssid" ]; then
  echo "$ssid"
else
  echo "Desconectado"
fi