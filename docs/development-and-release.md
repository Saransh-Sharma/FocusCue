# Development and Release

## Scope

This document covers local development builds, CI validation, release automation, required secrets, and failure diagnostics.

## Local build flows

## Distribution matrix

| Scheme | Configuration(s) | Distribution profile | Notes |
| --- | --- | --- | --- |
| `FocusCue` | `Debug`, `Release` | App Store | Uses `APP_STORE_BUILD`, `FocusCueAppStore.entitlements`, and hides Deepgram/OpenAI/updater. |
| `FocusCue Direct Debug` | `DirectDebug` | Direct | Local non-App-Store development surface. |
| `FocusCue Direct Release` | `DirectRelease` | Direct | Direct-download release/profile/archive surface. |

## Xcode build (recommended day-to-day)

1. Open `FocusCue.xcodeproj`.
2. Select a scheme based on the target surface:
   - `FocusCue` for App Store validation.
   - `FocusCue Direct Debug` for direct-distribution development.
   - `FocusCue Direct Release` for direct-distribution release verification.
3. Build/run with a macOS destination.

## Local StoreKit testing

FocusCue includes a committed local StoreKit configuration at `FocusCue/StoreKit/FocusCue.storekit`.

### Setup

1. Open `FocusCue.xcodeproj` in Xcode.
2. Select either `FocusCue` or `FocusCue Direct Debug`, depending on which distribution surface you want to test.
3. Open `Product > Scheme > Edit Scheme...`.
4. Confirm the `Run` action uses `FocusCue.storekit`.
5. If you add tests later, confirm the `Test` action also uses `FocusCue.storekit`.

### Local purchase test

1. Run the app from Xcode.
2. Open any Pro paywall surface.
3. Confirm the paywall shows a simulated price for the lifetime unlock.
4. Click `Unlock Pro`.
5. Approve the simulated StoreKit purchase dialog.
6. Confirm the app immediately switches to Pro branding and state.

### Local restore test

1. With the app running from Xcode, trigger `Restore Purchases`.
2. Confirm the app remains or returns to Pro if the simulated entitlement exists.

### Local refund / revoke test

1. In Xcode, open `Debug > StoreKit > Manage Transactions`.
2. Find the lifetime purchase transaction for `com.saransh1337.focuscue.pro.lifetime.teleprompter`.
3. Use the StoreKit testing UI to refund, revoke, or delete the transaction. The exact label can vary by Xcode version.
4. Return to the app and trigger an entitlement refresh path by relaunching the app or using `Restore Purchases`.
5. Confirm the app downgrades appropriately.

### Local reset state

1. In Xcode, open `Debug > StoreKit > Clear Transactions`, or use the equivalent action in the StoreKit transaction manager.
2. Relaunch the app.
3. Confirm the app behaves like a never-purchased user again.

### Caveat

Local `.storekit` testing simulates StoreKit only. It does not validate App Store Connect review status, metadata propagation, banking, tax, or TestFlight production wiring.

### Troubleshooting

- If the paywall shows no price locally:
  - Confirm the scheme is using `FocusCue.storekit`.
  - Confirm the product ID in `FocusCue.storekit` matches `StoreProductIDs.lifetimeProUnlock`.
  - Clean the build folder and relaunch.
- If purchase appears to do nothing:
  - Confirm the app was launched from Xcode with the shared scheme.
  - Confirm a simulated transaction was created in Xcode's StoreKit transaction manager.
- If restore fails locally:
  - Confirm the local transaction still exists.
  - Re-purchase once, then test restore again.

### Local QA checklist

- Product fetch shows a simulated price.
- Purchase flips the app to Pro.
- Relaunch preserves Pro.
- Restore works.
- Refund or revocation downgrades the app.
- Trial still works when no local transaction exists.

## CLI App Store debug build

```bash
xcodebuild build \
  -project /Users/saransh1337/Developer/Projects/FocusCue/FocusCue.xcodeproj \
  -scheme FocusCue \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO
```

## CLI direct debug build

```bash
xcodebuild build \
  -project /Users/saransh1337/Developer/Projects/FocusCue/FocusCue.xcodeproj \
  -scheme "FocusCue Direct Debug" \
  -configuration DirectDebug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO
```

## Local universal binary + DMG build

```bash
bash /Users/saransh1337/Developer/Projects/FocusCue/build.sh
```

`build.sh` performs:
1. arm64 archive
2. x86_64 archive
3. `lipo` merge into universal app
4. DMG staging and packaging

It now uses `FocusCue Direct Release` with `DirectRelease`, so local DMGs preserve the non-App-Store updater and cloud-integration surface.

Artifacts are written under:
- `/Users/saransh1337/Developer/Projects/FocusCue/build/release/`

## Build system structure

| File | Responsibility |
| --- | --- |
| [`../build.sh`](../build.sh) | Local universal archive + DMG flow |
| [`../FocusCue.xcodeproj/project.pbxproj`](../FocusCue.xcodeproj/project.pbxproj) | Build settings, entitlements, bundle ID, target config |
| [`../FocusCue.xcodeproj/xcshareddata/xcschemes/FocusCue.xcscheme`](../FocusCue.xcodeproj/xcshareddata/xcschemes/FocusCue.xcscheme) | Shared App Store scheme configuration |
| [`../FocusCue.xcodeproj/xcshareddata/xcschemes/FocusCue Direct Debug.xcscheme`](../FocusCue.xcodeproj/xcshareddata/xcschemes/FocusCue%20Direct%20Debug.xcscheme) | Shared direct-distribution debug scheme |
| [`../FocusCue.xcodeproj/xcshareddata/xcschemes/FocusCue Direct Release.xcscheme`](../FocusCue.xcodeproj/xcshareddata/xcschemes/FocusCue%20Direct%20Release.xcscheme) | Shared direct-distribution release scheme |

## CI workflow behavior

Workflow file: [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml)

### Trigger rules

- Push to `main`
- Pull request targeting `main`

### CI job behavior

- Runner: `macos-15`
- Action: checkout repository
- Build: App Store `Debug` and direct `DirectDebug` with `CODE_SIGNING_ALLOWED=NO`
- Concurrency: per-workflow/ref grouping with cancel-in-progress enabled

## Release workflow behavior

Workflow file: [`../.github/workflows/release.yml`](../.github/workflows/release.yml)

### Trigger rule

- Push tag matching `v*`

### Release stages

1. Checkout source.
2. Import signing certificate into temporary keychain.
3. Build direct-release app with `FocusCue Direct Release` / `DirectRelease`.
4. Code sign app with Developer ID identity.
5. Notarize zipped app and staple ticket.
6. Create DMG artifact.
7. Create GitHub release and upload DMG.

```mermaid
graph TD
    A["Tag push v*"] --> B["Import cert/keychain"]
    B --> C["xcodebuild DirectRelease"]
    C --> D["codesign FocusCue.app"]
    D --> E["notarytool submit + wait"]
    E --> F["stapler staple"]
    F --> G["create DMG"]
    G --> H["gh release create + upload"]
```

## Required secrets

| Secret | Used for |
| --- | --- |
| `APPLE_CERTIFICATE` | Base64 p12 for signing identity |
| `APPLE_CERTIFICATE_PASSWORD` | p12 import password |
| `APPLE_ID` | Apple account for notarization |
| `APPLE_PASSWORD` | App-specific password/token for notarization |
| `APPLE_TEAM_ID` | Team ID for notarization/auth |
| `GITHUB_TOKEN` | Release creation/upload API access |

## Validation checklist (pre-release)

1. CI debug build passes on latest `main`.
2. Local App Store debug build, local direct debug build, and local direct release build all succeed.
3. App launches and core smoke paths pass:
   - script edit/save/open
   - playback across selected modes
   - `.pptx` import
   - remote/external output check
   - updater/cloud integrations on direct schemes
4. Signing identity is detected in release runner output.
5. Notarization returns valid status and stapling completes.
6. DMG contains expected app bundle and installs cleanly.

## Common failure diagnostics

| Failure point | Symptom | Likely cause | Resolution |
| --- | --- | --- | --- |
| `xcodebuild` in CI | Build exit non-zero | project/scheme mismatch, SDK/runner changes, compile issue | Re-run with verbose local build and fix compile/config drift. |
| Signing step | No valid identity found | certificate secret malformed or missing | Recreate/export Developer ID p12, re-encode base64, update secret. |
| Notarization | Invalid/rejected submission | missing hardened runtime/signature issues | Inspect notarization log, ensure signed app and entitlements are valid. |
| DMG upload | release command fails | missing token permissions or release creation conflict | Validate `contents: write` permission and tag uniqueness. |
| Local universal build | lipo merge incomplete | architecture-specific archive failure | Verify both arm64/x86_64 archive outputs exist before merge. |

## Contributor workflow recommendation

1. Build both `FocusCue` and `FocusCue Direct Debug` locally before committing when touching distribution-sensitive code.
2. Keep documentation aligned with behavioral changes in source.
3. Avoid release-tag pushes until smoke checklist is complete.
4. For release changes, validate both workflow files and `build.sh` consistency.

## Related files

- [`../build.sh`](../build.sh)
- [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml)
- [`../.github/workflows/release.yml`](../.github/workflows/release.yml)
- [`../FocusCue.xcodeproj/project.pbxproj`](../FocusCue.xcodeproj/project.pbxproj)
- [`../FocusCue/FocusCue.entitlements`](../FocusCue/FocusCue.entitlements)
- [`../FocusCue/FocusCueAppStore.entitlements`](../FocusCue/FocusCueAppStore.entitlements)
