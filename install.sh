#!/bin/sh
# Instala o Starfield para o xfce4-screensaver (precisa de sudo).
set -e
cd "$(dirname "$0")"
sudo install -Dm755 starfield /usr/libexec/xfce4-screensaver/starfield
sudo install -Dm644 starfield.desktop /usr/share/applications/screensavers/starfield.desktop
xfconf-query -c xfce4-screensaver -p /saver/themes/list -n -t string -s screensavers-starfield -a
xfce4-screensaver-command --exit 2>/dev/null || true
nohup xfce4-screensaver >/dev/null 2>&1 &
echo "Starfield instalado e selecionado. Teste com: xfce4-screensaver-command --activate"
