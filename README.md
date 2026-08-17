# Cuprim

Free macOS menu-bar app that shows **Claude**, **Codex**, **Cursor**, **Grok**, and **Antigravity** quota usage.

**Local only** · no accounts · no telemetry · no cloud sync · light on RAM  
**Apple Silicon** · **macOS 26+** · MIT

**Website:** [cuprim.vercel.app](https://cuprim.vercel.app) · **Download:** [Releases](https://github.com/nawazish2/cuprim/releases/latest)

## Install

1. Download the latest **`.dmg`** from [Releases](https://github.com/nawazish2/cuprim/releases/latest)
2. Drag **Cuprim** into Applications
3. Open it — look for the gauge in the menu bar

### First open (Gatekeeper)

This build is ad-hoc signed (not notarized yet). If macOS blocks it:

- Right-click Cuprim → **Open**, or
- `xattr -cr /Applications/Cuprim.app`

### Requirements

- Apple Silicon (M1 or later)
- macOS 26+
- Providers you care about already signed in on the Mac:
  - Claude Code / Claude Desktop
  - Codex CLI (`~/.codex/auth.json`)
  - Cursor
  - Grok Build (`grok login`)

## Privacy

Credentials stay on your machine. Cuprim only talks to each provider’s own usage API. Nothing is sent to us — there is no backend.

## License

[MIT](LICENSE)
