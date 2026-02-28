#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${1}${RESET}"; }
success() { echo -e "${GREEN}${1}${RESET}"; }
warn()    { echo -e "${YELLOW}${1}${RESET}"; }
error()   { echo -e "${RED}${1}${RESET}"; }
bold()    { echo -e "${BOLD}${1}${RESET}"; }

CONFIG_FILE="$HOME/.config/bt-autoswitch/config"

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  error "Config file not found at $CONFIG_FILE"
  warn "Please run install.sh first."
  exit 1
fi

if [ -z "$CARD" ] || [ -z "$PROFILE_HQ" ] || [ -z "$PROFILE_MIC" ]; then
  error "Config is incomplete. Please re-run install.sh."
  exit 1
fi

POLL_INTERVAL="${POLL_INTERVAL:-2}"

CALL_APPS="${CALL_APPS:-discord chrome chromium firefox zoom teams slack webex}"

CURRENT=""

bold "bt-autoswitch started"
info "  Card:        $CARD"
info "  HQ profile:  $PROFILE_HQ"
info "  Mic profile: $PROFILE_MIC"
info "  Watching:    $CALL_APPS"
info "  Poll every:  ${POLL_INTERVAL}s"
echo ""

while true; do
  SINK_INPUTS=$(pactl list sink-inputs 2>/dev/null | grep -i "application.name\|application.process.binary" | tr '[:upper:]' '[:lower:]')

  IN_CALL=false
  for app in $CALL_APPS; do
    if echo "$SINK_INPUTS" | grep -q "$app"; then
      IN_CALL=true
      break
    fi
  done

  if [ "$IN_CALL" = true ]; then
    if [ "$CURRENT" != "mic" ]; then
      pactl set-card-profile "$CARD" "$PROFILE_MIC" 2>/dev/null && \
        warn "[$(date +%H:%M:%S)] Call detected — switched to headset mode ($PROFILE_MIC)" || \
        error "[$(date +%H:%M:%S)] Failed to switch to headset mode"
      CURRENT="mic"
    fi
  else
    if [ "$CURRENT" != "hq" ]; then
      pactl set-card-profile "$CARD" "$PROFILE_HQ" 2>/dev/null && \
        success "[$(date +%H:%M:%S)] No call — switched to high quality ($PROFILE_HQ)" || \
        error "[$(date +%H:%M:%S)] Failed to switch to high quality mode"
      CURRENT="hq"
    fi
  fi

  sleep "$POLL_INTERVAL"
done