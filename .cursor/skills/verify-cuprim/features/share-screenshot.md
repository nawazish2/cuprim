# Share screenshot

Share Screenshot builds a usage card for one enabled provider, copies it to the pasteboard, and activates the target AI app when possible.

## Sub-features

- `share-submenu` lists enabled providers under **Share Screenshot**
- `share-copy` places PNG (and summary text) on the general pasteboard
- `share-activate` attempts to bring Claude / ChatGPT / Cursor / Grok to the front

## How to get to it (user POV)

- Status menu → **Share Screenshot** → choose a provider name (Claude, Codex, Cursor, Grok)

## Driving it with verify-cuprim

Preconditions:

- Live instance; at least one provider enabled
- For a full path, that provider should have metrics (signed in); otherwise the card may still render a signed-out/error state — note which

- **Open submenu (manual).** Status menu → **Share Screenshot**. Submenu lists enabled providers only.
- **Share (manual).** Choose one provider. Target app may activate; pasteboard should hold an image.
- **Pasteboard check (scripted adjunct).** After sharing:

  ```bash
  osascript -e 'clipboard info' > evidence/<slug>/clipboard-info.txt
  ```

  Expect image-related types (PNG/TIFF) when share succeeded.
- **Screenshot proof.** Paste into Preview or a note and capture → `ui-share-card.png`, or screenshot the card if still on screen.

## Gotchas

- Submenu only includes **enabled** providers from preferences order
- Target apps may be missing; copy-to-pasteboard can still succeed when activate fails
- Don’t require network for this feature beyond whatever providers already need for metrics
- Codex share may activate ChatGPT bundle IDs — see `ScreenshotShare.Target`
