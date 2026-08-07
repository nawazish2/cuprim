# Cuprim App Icon — Apple standard (Icon Composer)

Apple’s pipeline for macOS 26+ utility Dock icons:

```
square layers (unmasked)
    → Icon Composer
    → AppIcon.icon  (layered Liquid Glass)
    → app bundle
```

## Rules (HIG)

| Do | Don’t |
|----|--------|
| Full-bleed **square** layers (1024×1024) | Pre-rounded squircles |
| Separate **background** + **foreground** | One flat baked icon only |
| Let **system mask** corners | Bake drop shadows outside the icon |
| Simple gauge silhouette | Tiny text / busy detail |

Official:

- [HIG – App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Icon Composer](https://developer.apple.com/icon-composer/)
- [Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)

## Files in this repo

```
Design/AppIcon/
  Layers/
    Background.png   # full-bleed dark fill (square)
    Foreground.png   # gauge on transparent (square)
  Preview-Composite-1024.png   # rough preview only
  README.md

Sources/Cuprim/Resources/AppIcon/
  AppIcon.icon/      # package for Icon Composer + app
    icon.json
    Assets/
  AppIcon.icns       # fallback for older tooling
  AppIcon-1024.png   # fallback flat master
```

## Automated (already done for Cuprim)

```bash
cd ~/Developer/cuprim
# Rebuild layered icon + exports + AppIcon.icns via Apple ictool
./script/build_app_icon.sh
# Package & launch
./script/build_and_run.sh
```

What the automation produces:

| Artifact | Purpose |
|----------|---------|
| `AppIcon.icon/` | Layered Icon Composer document (fill + groups + Assets) |
| `Exports/Cuprim-Default-1024.png` | Liquid Glass render (Default) |
| `Exports/Cuprim-Dark-1024.png` | Dark appearance export |
| `AppIcon.icns` | Dock/Finder sizes from Default export |

## Optional: open in Icon Composer to tweak

```bash
./script/open_icon_composer.sh
```

Save back to `Sources/Cuprim/Resources/AppIcon/AppIcon.icon`, then:

```bash
./script/build_app_icon.sh && ./script/build_and_run.sh
```

`build_and_run.sh` copies `AppIcon.icon` into `Cuprim.app` and sets `CFBundleIconName`.

## Menu bar icon (separate)

Menu bar stays **SF Symbol / template** — not the Dock icon. That is also Apple’s utility pattern.
