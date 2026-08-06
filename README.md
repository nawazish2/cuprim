# TokenBar

Free macOS menu-bar app that shows **Claude**, **Codex**, **Cursor**, and **Grok** quota usage.

**Local only** · no accounts · no telemetry · no cloud sync · light on RAM  
**Apple Silicon** · **macOS 26+** · MIT

## Install

1. Download the latest **`.dmg`** from [Releases](https://github.com/nawazish2/tokenbar/releases)
2. Drag **TokenBar** into Applications
3. Open it — look for the gauge in the menu bar

### First open (Gatekeeper)

This build is ad-hoc signed (not notarized yet). If macOS blocks it:

- Right-click TokenBar → **Open**, or
- `xattr -cr /Applications/TokenBar.app`

### Requirements

- Apple Silicon (M1 or later)
- macOS 26+
- Providers you care about already signed in on the Mac:
  - Claude Code / Claude Desktop
  - Codex CLI (`~/.codex/auth.json`)
  - Cursor
  - Grok Build (`grok login`)

## Privacy

Credentials stay on your machine. TokenBar only talks to each provider’s own usage API. Nothing is sent to us — there is no backend.

## Dev

```bash
./script/build_and_run.sh
```

Ship a release:

```bash
./script/release.sh
# → dist/TokenBar.app, .dmg, .app.zip
```

Notarized public builds: [docs/NOTARIZATION.md](docs/NOTARIZATION.md)

## License

[MIT](LICENSE)
