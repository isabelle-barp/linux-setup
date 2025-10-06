#!/usr/bin/env bash
# Requisitos: playerctl >= 2.0
# Mostra: [▶/⏸] Artista - Música (Álbum) 01:23/03:45
# Trunca com … se passar do limite (ajuste MAXLEN abaixo)

MAXLEN=${MAXLEN:-60}   # ajuste conforme a largura da sua polybar

status="$(playerctl --player=spotify status 2>/dev/null)"
if [[ $? -ne 0 ]]; then
  echo "  Spotify não está aberto"
  exit 0
fi

# Ícone do status
if [[ "$status" == "Playing" ]]; then
  icon=" ▶ "
elif [[ "$status" == "Paused" ]]; then
  icon="  "
else
  icon="⏹"
fi

# Metadados (evita 'Unknown' se vazio)
artist="$(playerctl --player=spotify metadata --format '{{artist}}' 2>/dev/null)"
title="$(playerctl --player=spotify metadata --format '{{title}}' 2>/dev/null)"
album="$(playerctl --player=spotify metadata --format '{{album}}' 2>/dev/null)"
artist="${artist:-Desconhecido}"
title="${title:-Sem título}"

# Tempos (em mm:ss)
time_now="$(playerctl --player=spotify metadata --format '{{duration(position)}}' 2>/dev/null)"
time_total="$(playerctl --player=spotify metadata --format '{{duration(mpris:length)}}' 2>/dev/null)"

# Monta a string base
if [[ -n "$album" ]]; then
  base="$artist - $title ($album)"
else
  base="$artist - $title"
fi

# Truncamento inteligente
# (remove excesso preservando o final da faixa)
len=${#base}
if (( len > MAXLEN )); then
  base="${base:0:MAXLEN-1}…"
fi

# Saída final com ícone do Spotify e status
# dica: requer Nerd Font (para )
if [[ -n "$time_now" && -n "$time_total" ]]; then
  echo "  [$icon] $base  $time_now/$time_total"
else
  echo "  [$icon] $base"
fi

