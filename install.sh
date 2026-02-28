#!/bin/bash
set -e

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

bold "bt-autoswitch installer"
echo ""

if ! command -v pactl &>/dev/null; then
  error "pactl not found. Install pulseaudio or pipewire-pulse and try again."
  exit 1
fi

info "Looking for Bluetooth audio card..."

mapfile -t CARDS < <(pactl list cards short | grep bluez | awk '{print $2}')

if [ "${#CARDS[@]}" -eq 0 ]; then
  error "No Bluetooth card found. Make sure your headset is connected and try again."
  exit 1
elif [ "${#CARDS[@]}" -gt 1 ]; then
  warn "Multiple Bluetooth cards found:"
  for i in "${!CARDS[@]}"; do
    echo "  $((i+1))) ${CARDS[$i]}"
  done
  echo ""
  read -rp "Which one is your headset? (enter number): " CHOICE
  CARD="${CARDS[$((CHOICE-1))]}"
else
  CARD="${CARDS[0]}"
fi

success "Using card: $CARD"
echo ""

mapfile -t ALL_PROFILES < <(pactl list cards | grep -A 200 "Name: $CARD" | grep -A 100 "Profiles:" | grep -B 100 "Active Profile:" | grep -oP '^\s+\K\S+(?=:)' | grep -v "Profiles\|Active\|off")

if [ "${#ALL_PROFILES[@]}" -eq 0 ]; then
  error "Could not read profiles for $CARD. Is the headset connected?"
  exit 1
fi

pick_profile() {
  local prompt="$1"
  warn "$prompt"
  for i in "${!ALL_PROFILES[@]}"; do
    echo "  $((i+1))) ${ALL_PROFILES[$i]}"
  done
  echo ""
  while true; do
    read -rp "Enter number: " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#ALL_PROFILES[@]}" ]; then
      echo "${ALL_PROFILES[$((CHOICE-1))]}"
      return
    fi
    error "Invalid choice, try again."
  done
}

PROFILE_HQ=""
PROFILE_MIC=""

for p in "${ALL_PROFILES[@]}"; do
  [[ "$p" == *a2dp* ]] && PROFILE_HQ="$p"
  [[ "$p" == *headset* || "$p" == *handsfree* ]] && PROFILE_MIC="$p"
done

if [ -z "$PROFILE_HQ" ]; then
  echo ""
  PROFILE_HQ=$(pick_profile "Could not auto-detect A2DP profile. Pick the HIGH QUALITY (no mic) profile:")
fi

if [ -z "$PROFILE_MIC" ]; then
  echo ""
  PROFILE_MIC=$(pick_profile "Could not auto-detect headset profile. Pick the MIC profile:")
fi

echo ""
info "  High quality profile: $PROFILE_HQ"
info "  Mic/headset profile:  $PROFILE_MIC"
echo ""
read -rp "Does this look right? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
case "$CONFIRM" in
  [Nn]*)
    echo ""
    PROFILE_HQ=$(pick_profile "Pick the HIGH QUALITY (no mic) profile:")
    echo ""
    PROFILE_MIC=$(pick_profile "Pick the MIC profile:")
    ;;
esac

CONFIG_DIR="$HOME/.config/bt-autoswitch"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/config" <<EOF
CARD="$CARD"
PROFILE_HQ="$PROFILE_HQ"
PROFILE_MIC="$PROFILE_MIC"
POLL_INTERVAL=2
EOF

success "Config saved to $CONFIG_DIR/config"

mkdir -p "$HOME/.local/bin"
cp "$(dirname "$0")/bt-autoswitch.sh" "$HOME/.local/bin/bt-autoswitch"
chmod +x "$HOME/.local/bin/bt-autoswitch"
success "Script installed to ~/.local/bin/bt-autoswitch"

mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/bt-autoswitch.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=bt-autoswitch
Comment=Auto-switch Bluetooth headset profile based on mic usage
Exec=/bin/bash $HOME/.local/bin/bt-autoswitch
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

success "Autostart entry created"
echo ""
bold "Installation complete!"
echo ""
info "bt-autoswitch will start automatically on your next login."
echo "To start it now:  bt-autoswitch &"
echo "To uninstall:     bash uninstall.sh"