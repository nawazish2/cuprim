# Notarization (optional)

TokenBar can ship as a free open-source `.app` / `.dmg` without the Mac App Store.

## Ad-hoc (dev / early OSS)

`./script/build_and_run.sh` and `./script/release.sh` default to ad-hoc signing (`codesign --sign -`). This is fine for local testing. Gatekeeper may warn first-time downloaders.

## Developer ID + notarization (recommended for public releases)

Requirements:

- Apple Developer Program membership
- Developer ID Application certificate in Keychain
- App-specific password or API key for `notarytool`

### 1. Sign the release

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./script/release.sh
```

### 2. Notarize the DMG

```bash
xcrun notarytool submit dist/TokenBar-0.1.2.dmg \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

xcrun stapler staple dist/TokenBar-0.1.2.dmg
```

Or use an App Store Connect API key:

```bash
xcrun notarytool submit dist/TokenBar-0.1.2.dmg \
  --key ~/AuthKey_XXXXXX.p8 \
  --key-id XXXXXX \
  --issuer YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY \
  --wait
```

### 3. Publish

Attach the stapled DMG (and/or `.app.zip`) to a GitHub Release.

Hardened Runtime and entitlements can be added later if notarization requires them for your signing setup.
