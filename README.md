# OpenCode NVIDIA Fix for Termux

One-command setup for running the Bun-compiled Android ARM64 OpenCode build with NVIDIA's OpenAI-compatible API, including the `supportsPromptCacheKey: false` compatibility setting that fixed the Nemotron request error.

## Quick install

Run this in **Termux on Android ARM64**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AadiVIP/opencode-nvidia-termux-fix/main/install.sh)
```

The script will:
1. Check that it is running in Termux on ARM64.
2. Install required Termux tools (`curl`, `jq`, `coreutils`).
3. Back up an existing OpenCode configuration.
4. Install/update the Bun-based Android build from [Astreele/opencode-android](https://github.com/Astreele/opencode-android), using its SHA-256-verified ZIP installer path.
5. Configure the NVIDIA provider and disable prompt-cache-key support at both provider and model level.
6. Prompt for an NVIDIA API key without echoing it, then save it locally with file permissions `0600`.
7. Verify the binary and configuration.

## What gets configured

- Provider: NVIDIA
- API base URL: `https://integrate.api.nvidia.com/v1`
- Default model: `nvidia/nvidia/nemotron-3-ultra-550b-a55b`
- Compatibility: `supportsPromptCacheKey: false` at provider and model level
- API key file: `~/.config/opencode/nvidia-api-key`

The script does **not** contain, request, or upload anyone's API key to this GitHub repository. Each user must provide their own NVIDIA API key. Press Enter at the prompt to skip key entry and configure it later.

## After installation

Start OpenCode:

```bash
opencode2
```

Check the installed version:

```bash
opencode2 --version
```

## Updating

Run the same one-line installer again. It re-runs the Android build installer and reapplies the NVIDIA compatibility configuration. Existing configuration is backed up first.

## Scope and notes

- Android ARM64 / Termux only.
- Installs the Android-native Bun-compiled build; it does not install Node.js or run OpenCode inside proot.
- Uses the upstream Android build project for the binary. This repository only automates installation and NVIDIA configuration.
- The default model must be available to the user's NVIDIA API account. Users can change the model in `~/.config/opencode/opencode.json`.
- The upstream Android build version can lag the latest desktop OpenCode release. Check [Astreele releases](https://github.com/Astreele/opencode-android/releases) for its current Android build version.

## Security

Review the installer before running it. API keys are written only to the local Termux home directory with restrictive permissions. Never paste an API key into a GitHub issue or commit it to a repository.

## License

MIT
