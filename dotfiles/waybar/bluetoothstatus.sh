# ¿Bluetooth está encendido?
bt_power=$(bluetoothctl show | grep "Powered" | awk '{print $2}')

if [[ "$bt_power" == "no" ]]; then
  echo "Off"
  exit
fi

# ¿Hay dispositivo conectado?
connected_device=$(bluetoothctl info | grep "Connected: yes")

if [[ -n "$connected_device" ]]; then
  name=$(bluetoothctl info | grep "Name:" | cut -d ' ' -f2-)
  echo "Conexión Bluetooth: $name"
else
  echo "No conectado"
fi
