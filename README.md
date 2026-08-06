# TokenBar

**Free and open source** macOS menu-bar utility that tracks **Claude**, **Codex**, **Cursor**, and **Grok** agent quotas.

Native Swift · **true Liquid Glass** · **Apple Silicon only** · **macOS 26+** · **MIT License**

No paywall. No license server. No telemetry.

## Features

- Menu bar gauge + optional remaining %
- Liquid Glass popover with per-provider meters and reset countdowns
- Reuses logins already on your Mac (no token paste)
- Auto-refresh every **2 minutes** (all providers) + manual refresh
- Settings with system glass chrome

## Requirements

- **Apple Silicon** (M1 or later) — Intel Macs are not supported
- **macOS 26+** — required for Liquid Glass
- Xcode 26+ / Swift 6.2
- Signed-in tools as needed:
  - Claude Code (`claude`) or `~/.claude/.credentials.json`
  - Codex CLI (`~/.codex/auth.json`)
  - Cursor app (local session)
  - Grok Build CLI (`grok login` → `~/.grok/auth.json`)

## Install (release)

Download the latest `.dmg` or `.app.zip` from [GitHub Releases](https://github.com/nawazish2/tokenbar/releases), then open TokenBar.

Early builds may be ad-hoc signed. Prefer a Developer ID + notarized build when available (see [docs/NOTARIZATION.md](docs/NOTARIZATION.md)).

## Build & run (dev)

```bash
cd ~/Developer/tokenbar
./script/build_and_run.sh
```

Builds **arm64 only** and packages `dist/TokenBar.app`.

```bash
swift build --arch arm64
swift test --arch arm64
```

## Release package

```bash
./script/release.sh
```

Produces:

- `dist/TokenBar.app`
- `dist/TokenBar-<version>.dmg`
- `dist/TokenBar-<version>.app.zip`

Optional Developer ID signing:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./script/release.sh
```

## App icon (Apple standard)

Dock / Finder icons use Apple’s **Icon Composer** pipeline (square layers → layered `.icon`):

```bash
./script/open_icon_composer.sh
```

See [Design/AppIcon/README.md](Design/AppIcon/README.md).  
Menu bar stays an **SF Symbol** (template) — separate from the Dock icon.

## Privacy & security

Credentials never leave your machine except to each provider’s own API. TokenBar does not send data to a license server, analytics backend, or third-party tracker.

| Provider | Source | Endpoint |
|---|---|---|
| Claude | Keychain / `~/.claude` | `api.anthropic.com/api/oauth/usage` |
| Codex | `~/.codex/auth.json` | `chatgpt.com/backend-api/wham/usage` |
| Cursor | Cursor `state.vscdb` | `cursor.com/api/usage-summary` |
| Grok | `~/.grok/auth.json` | Grok CLI billing/settings APIs |

Audit the source before running if you want to verify credential handling.

## Project layout

```
Sources/
  TokenBarCore/   pure models + formatting (testable)
  TokenBar/
    App/          menu bar + panel + settings window
    Providers/    Claude · Codex · Cursor · Grok
    Services/     HTTP + snapshot cache
    Stores/       usage + preferences
    Views/        glass dashboard + settings
    Support/      glass chrome, platform checks
Tests/TokenBarTests/
script/           build, release, icons
```

## Contributing

PRs welcome. Keep the app small.

1. Fork and clone
2. `swift test --arch arm64`
3. Prefer focused changes (one provider fix / one UI tweak)
4. Open a pull request with a short “why”

Issues that help most: provider API breakage, incorrect meters, and macOS 26 glass regressions.

## License

[MIT](LICENSE) — free forever for the core app. Optional sponsorship links may appear in Settings later; they will never gate features.

## Not included (on purpose)

CLI, local HTTP API, spend history, multi-account cards, Sparkle updates — keep the app small.
