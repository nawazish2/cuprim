# TokenBar

**Free and open source** macOS menu-bar utility that tracks **Claude**, **Codex**, **Cursor**, and **Grok** agent quotas.

Native Swift · **true Liquid Glass** · **Apple Silicon only** · **macOS 26+** · **MIT License**

No paywall. No license server. No telemetry.

## Features

- Menu bar gauge + optional remaining %
- Liquid Glass popover with per-provider meters and reset countdowns
- Reuses logins already on your Mac (no token paste)
- Auto-refresh every **2 minutes** (all providers) + manual refresh
- Share Screenshot — OpenUsage-style usage card per provider (clipboard + open app)
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

## Install (users)

1. Download the latest `.dmg` or `.app.zip` from [GitHub Releases](https://github.com/nawazish2/tokenbar/releases)
2. Open the DMG and drag **TokenBar** to Applications (or unzip the `.app`)
3. Launch TokenBar — look for the gauge in the menu bar

Gatekeeper may warn on first open if the build is not notarized. Prefer a Developer ID + notarized release when available.

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

## Distribute (ship a release)

TokenBar is **not** on the Mac App Store. You ship a signed `.app` / `.dmg` via GitHub Releases.

### 1. Bump the version

Edit `script/package_app.sh` → `Info.plist` keys:

- `CFBundleShortVersionString` (user-facing, e.g. `0.1.3`)
- `CFBundleVersion` (build number, e.g. `4`)

### 2. Build distributable artifacts

```bash
./script/release.sh
```

Produces:

| Artifact | Path |
|---|---|
| App | `dist/TokenBar.app` |
| DMG (drag to Applications) | `dist/TokenBar-<version>.dmg` |
| Zip | `dist/TokenBar-<version>.app.zip` |

Default signing is **ad-hoc** (`codesign -`). Fine for friends / testing. Gatekeeper will warn strangers.

### 3. Sign with Developer ID (recommended for public downloads)

Requires [Apple Developer Program](https://developer.apple.com/programs/) membership and a **Developer ID Application** certificate in Keychain.

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./script/release.sh
```

### 4. Notarize (so Gatekeeper trusts the download)

See the full steps in [docs/NOTARIZATION.md](docs/NOTARIZATION.md). Short version:

```bash
xcrun notarytool submit dist/TokenBar-0.1.2.dmg \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

xcrun stapler staple dist/TokenBar-0.1.2.dmg
```

### 5. Publish on GitHub

```bash
# Example with GitHub CLI
gh release create v0.1.2 \
  dist/TokenBar-0.1.2.dmg \
  dist/TokenBar-0.1.2.app.zip \
  --title "TokenBar 0.1.2" \
  --notes "Release notes here."
```

Or upload the DMG / zip manually on the [Releases](https://github.com/nawazish2/tokenbar/releases) page.

**Checklist before publishing**

- [ ] Version bumped in `package_app.sh`
- [ ] `./script/release.sh` succeeded
- [ ] App opens on a clean Apple Silicon Mac (macOS 26+)
- [ ] Providers you care about show meters when signed in
- [ ] Developer ID signed + notarized (for public downloads)
- [ ] Stapled DMG attached to the GitHub Release

## App icon

Dock / Finder / About use the packaged `AppIcon.icns`. Rebuild from Icon Composer layers:

```bash
./script/build_app_icon.sh
./script/open_icon_composer.sh   # optional visual tweak
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
    Views/        glass dashboard + share card + settings
    Support/      glass chrome, screenshot share, platform checks
Tests/TokenBarTests/
script/           build, release, icons
docs/             notarization / distribution
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
