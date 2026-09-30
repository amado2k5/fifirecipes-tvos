# App Store submission checklist — FiFi Recipes for Apple TV 1.0

## Identity

| Item | Value |
|------|-------|
| Name | FiFi Recipes |
| Bundle ID | `cooking.fifi.tvos` |
| Version | 1.0 |
| Category | **Food & Drink** (NOT Kids — kids mode is a feature, app is for grown-ups) |
| Copyright | © 2026 Dr. Fatma / FiFi |
| Support URL | https://tvosapp.fifi.cooking/support.html |
| Privacy URL | https://tvosapp.fifi.cooking/privacy.html |
| Marketing URL | https://tvosapp.fifi.cooking |

## Technical compliance (done in-repo)

- [x] Native SwiftUI app, not a hosted WebView (Guideline 4.2)
- [x] `PrivacyInfo.xcprivacy` — no required-reason APIs beyond declarations
- [x] `ITSAppUsesNonExemptEncryption = false` (plain HTTPS only)
- [x] Launch screen (solid paper color via `UILaunchScreen`)
- [x] Layered (parallax) app icon: 400×240 + 1280×768 (App Store),
      back/middle/front imagestacks
- [x] Top Shelf image (1920×720) + Top Shelf Image Wide (2320×720)
- [x] Apple TV only (`TARGETED_DEVICE_FAMILY=3`)
- [x] No third-party SDKs, no analytics, no tracking
- [x] Min tvOS 17 deployment target
- [x] Siri Remote only — no game controller or companion-app requirement

## Focus & remote (Apple TV Human Interface Guidelines)

- [x] Every interactive element is a real `Button` — focus engine handles it
- [x] Focused cards scale/lift with a visible ring (not just a subtle dim)
- [x] Menu button = back; no traps (every screen pops with Menu)
- [x] Search uses the system full-screen keyboard/dictation field
- [x] Large targets, no hover-precision gestures
- [x] No scroll-and-tap timing hazards (rails use `.scrollTargetBehavior`)

## Accessibility

- [x] Text scales via Dynamic Type text styles (bundled fonts participate)
- [x] VoiceOver labels/hints on cards and controls; decorative art is
      `accessibilityHidden`
- [x] RTL mirroring for ar/ur/fa/ps/he/ku
- [x] Reduce Motion honored (focus scale, confetti, transitions disabled)

## Age rating answers

- Objectionable content: **none**
- Unrestricted web access: **NO** — content is curated JSON from
  fifi.cooking; videos open in the YouTube app (external, Apple's
  sanctioned path for YouTube on tvOS)
- User-generated content / social: **none**
- Kids category: **NO**

## Privacy nutrition label

**Data Not Collected** — no accounts, identifiers, usage data, or
diagnostics leave the device. Videos hand off to the YouTube app (Google's
policy applies there); disclosed in `site/privacy.html`. Verify at
submission that no embed/analytics have crept in.

## Blocked on Apple Developer account

- [ ] Enroll ($99/yr, individual or org + D-U-N-S)
- [ ] App Store Connect app record (SKU suggestion: `fifi-recipes-tvos`)
- [ ] Signing + archive + upload via Xcode (Organizer → tvOS)
- [ ] Screenshots — App Store wants Apple TV 4K shots at 1920×1080;
      `FifiRecipesTVUITests/ScreenshotTests` captures home/recipe/kids/RTL
      into the `.xcresult` bundle for export
- [ ] Top Shelf preview in App Review — supplied via the brandassets
      Top Shelf image already in the catalog
- [ ] App Review notes: mention test account not needed (no login),
      videos require network, kids mode is a feature not a Kids app
