# bt-autoswitch

Automatically switches your Bluetooth headset between **A2DP** (high quality audio, no mic) and **HSP/HFP** (headset mode with mic) based on whether your microphone is actively in use.

No more manually switching profiles in `pavucontrol` every time you jump on a call.

---

## How it works

A lightweight background script polls PulseAudio/PipeWire every 2 seconds. When an app starts using your mic, it switches to headset mode. When the mic goes idle, it switches back to A2DP for better audio quality.

## Requirements

- Linux (Ubuntu, Fedora, Arch, etc.)
- PulseAudio **or** PipeWire with `pipewire-pulse`
- A Bluetooth headset that supports both A2DP and HSP/HFP profiles

Check if you have `pactl`:
```bash
pactl --version
```
If not, install it:
```bash
# Ubuntu/Debian
sudo apt install pulseaudio-utils

# Arch
sudo pacman -S libpulse
```

## Install

```bash
git clone https://github.com/kingtusks/bt-autoswitch
cd bt-autoswitch
bash install.sh
```

The installer will:
1. Auto-detect your Bluetooth headset
2. Auto-detect your A2DP and headset profiles
3. Ask you to confirm (or manually enter them if detection fails)
4. Install the script to `~/.local/bin/`
5. Create an autostart entry so it runs on login

To start it immediately without rebooting:
```bash
bt-autoswitch &
```

## Uninstall

```bash
bash uninstall.sh
```

## Manual setup / troubleshooting

If auto-detection fails, you can find your card and profiles manually:

```bash
# Find your card name
pactl list cards short

# List profiles for your card (replace with your card name)
pactl list cards | grep -A 80 "Name: bluez_card.XX_XX_XX_XX_XX_XX" | grep -E "^\s+(a2dp|headset|handsfree)"
```

Then edit the config directly:
```bash
nano ~/.config/bt-autoswitch/config
```

```bash
CARD="bluez_card.XX_XX_XX_XX_XX_XX"
PROFILE_HQ="a2dp_sink"
PROFILE_MIC="headset_head_unit"
POLL_INTERVAL=2
```

Common profile names:
| Profile | Description |
|---|---|
| `a2dp_sink` | High quality audio, no mic |
| `headset_head_unit` | HSP/HFP headset mode with mic |
| `handsfree_head_unit` | HFP handsfree mode with mic |

## Configuration

| Option | Default | Description |
|---|---|---|
| `CARD` | auto | Your Bluetooth card name |
| `PROFILE_HQ` | auto | A2DP profile name |
| `PROFILE_MIC` | auto | HSP/HFP profile name |
| `POLL_INTERVAL` | `2` | Seconds between checks (lower = faster switching but more CPU) |

## Contributing

Issues and PRs welcome. If the installer fails to detect your card or profiles, open an issue with the output of:
```bash
pactl list cards
```