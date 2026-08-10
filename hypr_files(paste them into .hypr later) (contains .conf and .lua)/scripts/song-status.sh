#!/bin/bash
STATUS=$(playerctl --ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera status 2>/dev/null)
if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
    SONG=$(playerctl --ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera metadata --format "{{ artist }} - {{ title }}" 2>/dev/null)
    if [ -n "$SONG" ]; then
        echo "🎵 $SONG"
    else
        echo ""
    fi
else
    echo ""
fi
