#!/usr/bin/env bash

# Obtener SSID actual conectado
current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

# Obtener lista única de redes y marcar la actual
wifi_list=$(nmcli -t -f SSID dev wifi | awk '!seen[$0]++' | grep -v '^$' | while read -r ssid; do
  if [[ "$ssid" == "$current_ssid" ]]; then
    echo "[x] $ssid"
  else
    echo "    $ssid"
  fi
done)

# Mostrar menú con estilo
chosen=$(echo "$wifi_list" | rofi -dmenu \
  -theme-str '  
    window { 
        width: 20%; 
        border: 2px solid;
        border-radius: 10px;
        padding: 10px;
    } 
    listview { 
        lines:  10;
    }
    element selected normal, element selected active {
        background-color: #89b4fa;
        text-color: #1e1e2e;
    }
    element {
        padding: 6px;
    }
  ' \
  -p "  Selecciona tu red Wi-Fi:" \
  -i)

# Limpiar el marcador ASCII antes de conectar
chosen_cleaned=$(echo "$chosen" | sed 's/^\[[xX]\] *//')
chosen_cleaned=$(echo "$chosen_cleaned" | sed 's/^[[:space:]]*//')

if [ -n "$chosen_cleaned" ]; then
  # Verifica si la red requiere contraseña
  secured=$(sudo nmcli -f SSID,SECURITY dev wifi | grep "$chosen_cleaned" | grep -q WPA && echo "yes" || echo "no")

  if [ "$secured" = "yes" ]; then
    pass=$(rofi -dmenu -p "🔒 Introduce la contraseña:" \
            -theme-str 'window { 
                width: 40%; 
                border: 2px solid;
                border-radius: 10px;
                padding: 10px;
                height: 40px;
            }')
    sudo nmcli dev wifi connect "$chosen_cleaned" password "$pass"
  else
    sudo nmcli dev wifi connect "$chosen_cleaned"
  fi
fi
