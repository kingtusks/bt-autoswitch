#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}bt-autoswitch uninstaller${RESET}"
echo ""

REMOVED=0

if pgrep -f "bt-autoswitch" &>/dev/null; then
  pkill -f "bt-autoswitch" && echo -e "${YELLOW}Stopped running bt-autoswitch process${RESET}"
  REMOVED=$((REMOVED + 1))
fi

if [ -f "$HOME/.local/bin/bt-autoswitch" ]; then
  rm "$HOME/.local/bin/bt-autoswitch"
  echo -e "${GREEN}Removed ~/.local/bin/bt-autoswitch${RESET}"
  REMOVED=$((REMOVED + 1))
fi

if [ -f "$HOME/.config/autostart/bt-autoswitch.desktop" ]; then
  rm "$HOME/.config/autostart/bt-autoswitch.desktop"
  echo -e "${GREEN}Removed autostart entry${RESET}"
  REMOVED=$((REMOVED + 1))
fi

if [ -d "$HOME/.config/bt-autoswitch" ]; then
  read -rp "Remove config at ~/.config/bt-autoswitch? [Y/n]: " CONFIRM
  CONFIRM="${CONFIRM:-Y}"
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/bt-autoswitch"
    echo -e "${GREEN}Removed config directory${RESET}"
    REMOVED=$((REMOVED + 1))
  else
    echo -e "${YELLOW}Config kept at ~/.config/bt-autoswitch${RESET}"
  fi
fi

echo ""
if [ "$REMOVED" -gt 0 ]; then
  echo -e "${BOLD}Uninstall complete${RESET}"
else
  echo -e "${RED}Nothing to remove — bt-autoswitch does not appear to be installed.${RESET}"
fi