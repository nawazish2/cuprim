# About

About Cuprim shows the branded about panel: icon, name, version, author credit, and GitHub link.

## Sub-features

- `about-open` opens the About window from status menu, app menu, or Settings
- `about-version` displays the marketing/build version string consistent with the packaged app
- `about-links` exposes author and GitHub links

## How to get to it (user POV)

- Status menu → **About Cuprim**
- App menu → **About Cuprim**
- Settings → About → **About Cuprim…**

## Driving it with verify-cuprim

Preconditions:

- Live instance from this run’s package (so version matches Info.plist)

- **Open (manual).** Choose **About Cuprim**. Centered about UI with Cuprim title.
- **Version check.** Compare on-screen version to:

  ```bash
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/Cuprim.app/Contents/Info.plist
  ```

  Record both in `NOTES.md`.
- **Screenshot.** `evidence/<slug>/ui-about.png` showing name + version.

## Gotchas

- Version mismatches mean you launched a different binary (Applications vs `dist/`)
- Don’t bump plist version as part of verification
- Links open in a browser — optional to click; presence of the link control is enough unless the claim is URL correctness
