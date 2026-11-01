#!/data/data/com.termux/files/usr/bin/bash
# OpenCode + NVIDIA Nemotron setup for Termux (Android ARM64).
set -Eeuo pipefail
UPSTREAM_INSTALLER="https://raw.githubusercontent.com/Astreele/opencode-android/master/install.sh"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_DIR="$HOME/.config/opencode"
CONFIG="$CONFIG_DIR/opencode.json"
KEY_FILE="$CONFIG_DIR/nvidia-api-key"
MODEL="nvidia/nvidia/nemotron-3-ultra-550b-a55b"
MODEL_KEY="nvidia/nemotron-3-ultra-550b-a55b"
BASE_URL="https://integrate.api.nvidia.com/v1"
say(){ printf '\n==> %s\n' "$*"; }
die(){ printf '\nERROR: %s\n' "$*" >&2; exit 1; }
[ -n "${PREFIX:-}" ] || die "Run this inside Termux."
case "$(uname -m)" in aarch64|arm64) ;; *) die "Android ARM64 only; detected $(uname -m).";; esac
command -v pkg >/dev/null 2>&1 || die "Termux package manager not found."
say "Installing required tools"
pkg update -y
pkg install -y curl jq coreutils
say "Backing up existing configuration"
mkdir -p "$CONFIG_DIR"; chmod 700 "$CONFIG_DIR"
backup=""
if [ -f "$CONFIG" ]; then
  backup="$CONFIG.pre-nvidia-fix.$(date +%Y%m%d-%H%M%S).bak"
  cp -p "$CONFIG" "$backup"; echo "Backup: $backup"
fi
say "Installing Bun-based Android OpenCode"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fL --retry 3 "$UPSTREAM_INSTALLER" -o "$tmp/upstream-install.sh"
# Keep an existing v1 'opencode' command untouched; install v2 as opencode2.
bash "$tmp/upstream-install.sh" --zip --no-link --force
command -v opencode2 >/dev/null 2>&1 || die "opencode2 was not installed."
say "Configuring NVIDIA provider compatibility"
if [ -f "$CONFIG" ]; then jq empty "$CONFIG" >/dev/null 2>&1 || die "Existing opencode.json is invalid JSON; backup retained at $backup."; else printf '{}\n' > "$CONFIG"; fi
jq --arg model "$MODEL" --arg modelkey "$MODEL_KEY" --arg base "$BASE_URL" '
  . + {"$schema": (."$schema" // "https://opencode.ai/config.json"), "model": $model}
  | .provider = (.provider // {})
  | .provider.nvidia = ((.provider.nvidia // {}) + {
      "npm":"@ai-sdk/openai-compatible",
      "name":"NVIDIA",
      "options": ((.provider.nvidia.options // {}) + {"baseURL":$base,"apiKey":"{file:~/.config/opencode/nvidia-api-key}"}),
      "compatibility": ((.provider.nvidia.compatibility // {}) + {"supportsPromptCacheKey":false}),
      "models": ((.provider.nvidia.models // {}) + {
        ($modelkey): ((.provider.nvidia.models[$modelkey] // {}) + {
          "name":"Nemotron 3 Ultra",
          "compatibility": ((.provider.nvidia.models[$modelkey].compatibility // {}) + {"supportsPromptCacheKey":false})
        })
      })
    })
' "$CONFIG" > "$tmp/config.json"
install -m 600 "$tmp/config.json" "$CONFIG"
say "NVIDIA API key"
echo "Paste your own NVIDIA API key. It is stored locally with mode 600, never uploaded."
if [ -t 0 ]; then read -r -s -p "NVIDIA API key (Enter to skip): " api_key; printf '\n'; else api_key=""; fi
if [ -n "${api_key:-}" ]; then
  case "$api_key" in nvapi-*) ;; *) unset api_key; die "Expected an NVIDIA key beginning nvapi-."; esac
  umask 077; printf '%s' "$api_key" > "$KEY_FILE"; chmod 600 "$KEY_FILE"; unset api_key
  echo "API key saved securely."
else echo "Skipped. Save your key later to $KEY_FILE and run chmod 600 on it."; fi
say "Verifying installation"
version="$(opencode2 --version 2>&1)" || die "OpenCode failed to start."
printf 'Installed: %s\n' "$version"
jq -e '.provider.nvidia.compatibility.supportsPromptCacheKey == false and .provider.nvidia.models["nvidia/nemotron-3-ultra-550b-a55b"].compatibility.supportsPromptCacheKey == false and .model == "nvidia/nvidia/nemotron-3-ultra-550b-a55b"' "$CONFIG" >/dev/null || die "Compatibility config verification failed."
echo "Provider + model compatibility flags verified."
echo "Done. Start OpenCode with: opencode2"
echo "Model: $MODEL"
echo "Your API key is not part of this repository."
