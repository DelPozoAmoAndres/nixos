# Estado de reproducción de Chromium
player_status_chromium=$(playerctl -p chromium status 2> /dev/null)
# Estado de reproducción de Brave
player_status_brave=$(playerctl -p brave status 2> /dev/null)

case "$player_status_chromium" in
    "Playing")
        # Si Chromium está reproduciendo, mostrarlo con prioridad
        echo "   $(playerctl -p chromium metadata artist) - $(playerctl -p chromium metadata title)"
        ;;
    "Paused")
        # Si Chromium está pausado, verificar el estado de Brave
        case "$player_status_brave" in
            "Playing")
                # Si Brave está reproduciendo, mostrarlo
                title=$(playerctl -p brave metadata title)
                
                # Verifica si el título contiene "Twitch"
                if [[ "$title" == *"Twitch"* ]]; then
                    title_no_twitch=$(echo "$title" | sed 's/- Twitch//g')
                    echo "  $title_no_twitch"
                else
                    echo " $(playerctl -p brave metadata artist) - $title"
                fi
                ;;
            "Paused")
                # Si ninguno está reproduciendo pero ambos están pausados, mostrar Chromium pausado
                echo "   $(playerctl -p chromium metadata artist) - $(playerctl -p chromium metadata title)"
                ;;
            *)
                # Si Brave no está sonando o pausado, mostrar Chromium pausado
                echo "   $(playerctl -p chromium metadata artist) - $(playerctl -p chromium metadata title)"
                ;;
        esac
        ;;
    *)
        title=$(playerctl -p brave metadata title)
        # Si Chromium no está sonando, verificar el estado de Brave
        if [ "$player_status_brave" = "Playing" ]; then
            
            # Verifica si el título contiene "Twitch"
            if [[ "$title" == *"Twitch"* ]]; then
                title_no_twitch=$(echo "$title" | sed 's/- Twitch//g')
                echo "  $title_no_twitch"
            else
                echo "   $(playerctl -p brave metadata artist) - $title"
            fi
        elif [ "$player_status_brave" = "Paused" ]; then
            # Si Brave está pausado, mostrarlo
            if [[ "$title" == *"Twitch"* ]]; then
                title_no_twitch=$(echo "$title" | sed 's/- Twitch//g')
                echo "  $title_no_twitch"
            else
                echo "   $(playerctl -p brave metadata artist) - $(playerctl -p brave metadata title)"
            fi
        fi
        ;;
esac
