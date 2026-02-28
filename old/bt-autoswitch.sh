#!/bin/bash
#the config below should be filled out with install.sh but if it aint then jus do it manually

CARD=""
PROFILE_HQ=""
PROFILE_MIC=""
POLL_INTERVAL=2

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

CONFIG_FILE="$HOME/.config/bt-autoswitch/config"

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo -e "${RED}ERROR: Config file not found at $CONFIG_FILE${RESET}"
  echo -e "${YELLOW}Please run install.sh first.${RESET}"
  exit 1
fi

if [ -z "$CARD" ] || [ -z "$PROFILE_HQ" ] || [ -z "$PROFILE_MIC" ]; then
  echo -e "${RED}ERROR: Config is incomplete. Please re-run install.sh.${RESET}"
  exit 1
fi

CURRENT=""

echo -e "${BOLD}bt-autoswitch started${RESET}"
echo -e "${CYAN}  Card:        $CARD${RESET}"
echo -e "${CYAN}  HQ profile:  $PROFILE_HQ${RESET}"
echo -e "${CYAN}  Mic profile: $PROFILE_MIC${RESET}"
echo -e "${CYAN}  Poll every:  ${POLL_INTERVAL}s${RESET}"
echo ""

while true; do
  MIC_ACTIVE=$(pactl list source-outputs 2>/dev/null | grep -c "Source Output")

  if [ "$MIC_ACTIVE" -gt 0 ]; then
    if [ "$CURRENT" != "mic" ]; then
      pactl set-card-profile "$CARD" "$PROFILE_MIC" 2>/dev/null && \
        echo -e "${YELLOW}[$(date +%H:%M:%S)] Mic in use > switched to headset mode ($PROFILE_MIC)${RESET}" || \
        echo -e "${RED}[$(date +%H:%M:%S)] WARNING: Failed to switch to headset mode${RESET}"
      CURRENT="mic"
    fi
  else
    if [ "$CURRENT" != "hq" ]; then
      pactl set-card-profile "$CARD" "$PROFILE_HQ" 2>/dev/null && \
        echo -e "${GREEN}[$(date +%H:%M:%S)] Mic idle > switched to high quality ($PROFILE_HQ)${RESET}" || \
        echo -e "${RED}[$(date +%H:%M:%S)] WARNING: Failed to switch to high quality mode${RESET}"
      CURRENT="hq"
    fi
  fi

  sleep "$POLL_INTERVAL"
done