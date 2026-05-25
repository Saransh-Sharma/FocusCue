# Phase 7 Audit

## 1. Phase scope
Build script and CI/release workflow parity.

## 2. FocusCue files implemented
- `build.sh`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

## 3. Reference files compared
- `autoprompter-main/AutoPrompter/build.sh`
- `autoprompter-main/.github/workflows/ci.yml`
- `autoprompter-main/.github/workflows/release.yml`

## 4. Symbol parity check
- Universal archive flow retained.
- Release pipeline stages retained (import cert, build, sign, notarize, DMG, upload).

## 5. Behavior parity check
- Artifact naming updated to FocusCue.
- Project/entitlements paths corrected for root-level layout.
- `build.sh` updated with `CODE_SIGNING_ALLOWED=NO` for local unsigned archive generation.

## 6. Allowed deviations
- FocusCue naming and root-path updates.
- Unsiged local archive convenience flag in build script.

## 7. Unexpected deviations
- None.

## 8. Open risks
- Full release workflow depends on secrets and notarization credentials.

## 9. Gate result
PASS
