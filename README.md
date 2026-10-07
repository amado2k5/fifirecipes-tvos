# FiFi Recipes — tvOS

Native SwiftUI Apple TV companion to [fifi.cooking](https://fifi.cooking),
the recipe site by Dr. Fatma / FiFi. Not a WebView wrapper: every screen is
real SwiftUI consuming the static JSON API at `https://fifi.cooking/data/` —
the same contract the Fire TV app uses (`docs/tv-api.md` in the `fifirecipes`
repo, reference client in `fifirecipes-amazonfire`).

- **Bundle ID:** `cooking.fifi.tvos` · **Min tvOS:** 17 · **Swift:** 6
- **Dependencies:** none — URLSession, AsyncImage, Foundation only
- **Website:** https://tvosapp.fifi.cooking (GitHub Pages, `site/`)

## Build & test

```sh
# Build (simulator)
xcodebuild -project FifiRecipesTV.xcodeproj -scheme FifiRecipesTV \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  build CODE_SIGNING_ALLOWED=NO

# Unit + UI tests
xcodebuild -project FifiRecipesTV.xcodeproj -scheme FifiRecipesTV \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  test CODE_SIGNING_ALLOWED=NO
```

UI tests hit the live `fifi.cooking` API (the product is online-only) and
drive the app through `XCUIRemote` — every interaction is a real remote
press, which exercises the focus engine end-to-end. Launch arguments
supported for tests/screenshots:

| Arg | Effect |
|-----|--------|
| `-fifi.reset 1` | Clear persisted language → first-run picker |
| `-fifi.language ar` | Preselect a language |
| `-fifi.apiOrigin <url>` | Point the API elsewhere (offline test) |

## tvOS design notes

- **Focus engine.** All cards/buttons are native `Button`s with custom
  `ButtonStyle`s (`FifiCardButton`, `FifiRowButton`, `KidsButton`) driven by
  `@Environment(\.isFocused)` — scale/lift/highlight on focus, honoring
  Reduce Motion. No custom focus logic; directional navigation is the
  system's, so it behaves like every other tvOS app.
- **Remote.** Menu = back (system `NavigationStack` pop). Play/Pause opens
  video links. Search uses the standard tvOS `searchable` field — focus it
  to get the full-screen dictation keyboard.
- **Icons.** `App Icon & Top Shelf Image.brandassets` has the required
  layered (parallax) icon — back/middle/front imagestacks — plus Top Shelf
  images, all rendered by `scripts/generate-tv-icons.py` (Pillow; re-run to
  regenerate). A focused icon parallaxes; the Top Shelf banner shows the
  emblem + wordmark.
- **Layout.** `FifiLayout` constants (screen margins, rail card width)
  tuned for the 10-foot experience; content sits inside the tvOS safe area.

## Architecture

```
FifiRecipesTV/
├── App/            @main App, RootView (phase router), AppState
│                   (manifest → picker → tabs; per-tab NavigationPath)
├── API/            APIClient — actor; manifest-driven endpoint templates,
│                   ?v= versioned requests, in-flight + URLCache caching,
│                   kids English-fallback on 404; AssetURL resolver
├── Models/         Codable models mirroring src/api/types.ts
├── Localization/   Strings (26 languages from bundled ui-strings.json,
│                   allergen map) + RecipeLocalization (ar master-fallback,
│                   never-English cultural notes, ui.text/textEn precedence)
├── Theme/          Palette (fresh-market colors) + FifiFont
│                   (per-language OFL faces, Dynamic Type via text styles)
├── Components/     RemoteImage (AsyncImage + branded placeholder), cards,
│                   error/skeleton states, VideoOpener (YouTube handoff)
├── Screens/        LanguagePicker, Home, Chapters(+detail), Search,
│                   RecipeDetail, Settings
└── KidsMode/       Kids catalogue, ready checklist, step-by-step,
                    celebration, bundled PNG illustrations, Baloo fonts
```

### Localization

26 languages, RTL (`ar`, `ur`, `fa`, `ps`, `he`, `ku`) flips layout via
`.environment(\.layoutDirection)`. UI strings and allergen names are bundled
from the TV repo's `strings.ts` (via `scripts/export-strings.cjs` →
`ui-strings.json`) plus the tvOS-only `youtubeAppNeeded` key. Fonts are
bundled OFL Google Fonts selected per language: Plus Jakarta Sans (Latin),
Tajawal (ar/RTL), Vazirmatn (fa), Noto Nastaliq Urdu (ur), Heebo (he),
Baloo 2/Baloo Bhaijaan 2 (kids mode) — all through Dynamic Type text styles.

### Videos

`WKWebView` doesn't exist on tvOS, so recipe videos can't play in-app.
`VideoOpener` hands the watch URL to the system; when the YouTube app is
installed it opens the video there. When it isn't, the app shows the
localized `youtubeAppNeeded` hint ("install YouTube from the App Store").
This matches Apple's guidance — third-party apps can't embed web video on
tvOS, and YouTube's own app is the supported player.

## Privacy posture

No accounts, no analytics, no crash SDKs, no tracking. App Store privacy
label: **Data Not Collected**. On-device storage is limited to the selected
language (UserDefaults) and URL caches. `PrivacyInfo.xcprivacy` is bundled;
`ITSAppUsesNonExemptEncryption=false` (plain HTTPS).

## CI

- `.github/workflows/pages.yml` — deploys `site/` to GitHub Pages
  (`tvosapp.fifi.cooking`) on pushes to `main`.
- `.github/workflows/tvos-ci.yml` — builds and runs unit + UI smoke tests on
  `macos-latest`, dynamically picking an available Apple TV simulator.
  Note: private repos get limited free GitHub Actions minutes and macOS
  runners bill at 10× — the workflow is also `workflow_dispatch`-able.

## Repo layout

```
site/           Static Pages site (landing, support.html, privacy.html,
                CNAME → tvosapp.fifi.cooking)
docs/           screenshots/ contact sheet
scripts/        resource generators (ui-strings export, brandassets render)
STORE.md        App Store submission checklist + current answers
```

## App Store status

See `STORE.md`. Summary: app is build- and feature-complete for a 1.0
submission; remaining items need an Apple Developer account (signing,
screenshots from a real Apple TV, App Store Connect record).
