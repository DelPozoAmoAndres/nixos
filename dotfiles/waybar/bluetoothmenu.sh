# Obtener dispositivo conectado
connected_mac=$(sudo bluetoothctl info | grep "Device" | awk '{print $2}')

device_list=$(sudo hcitool scan | while read -r mac name; do
  if [ "$mac" = "$connected_mac" ]; then
    echo "[x] $name ($mac)"
  else
    echo "    $name ($mac)"
  fi
done)

# Mostrar menú con rofi
chosen=$(echo "$device_list" | rofi -dmenu \
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
  -p " Selecciona Bluetooth:" \
  -i)

# Limpiar el texto para extraer la MAC
chosen_mac=$(echo "$chosen" | sed -E 's/.*\(([^)]+)\)/\1/')

if [ -n "$chosen_mac" ]; then
  sudo bluetoothctl connect "$chosen_mac"
fi
