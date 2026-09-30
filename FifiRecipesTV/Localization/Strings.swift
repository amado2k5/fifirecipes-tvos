import Foundation

/// UI string keys — identical names to the TV app's UIStrings
/// (src/i18n/strings.ts), so the two clients stay in lock-step.
enum SKey: String, CaseIterable {
    case appName, tagline, home, chapters, search, kids, settings
    case chooseLanguage, loading, errorTitle, errorBody, retry
    case searchTitle, searchHint, noResults
    case ingredients, steps, alternativeMethods, culturalNotes, tips, videos
    case openInYouTube, close, prep, cook, servings, ages, minutesShort
    case grownUp, noCook, tip, tools, language, about, aboutText, version
    case kcal, protein, carbs, fat, playPause, resultsFor
    case all, groupBreakfast, groupSnack, groupSavoury, groupSweet, groupDrink
    case letsCook, getReady, washHands, wearApron, stepOf, doneTitle, doneBody
    case cookAgain, contains, tickHint, next, prev, finish
    // tvOS-only: shown when tapping a video and the YouTube app is absent
    // (there is no WKWebView on tvOS, so videos always hand off to YouTube).
    case youtubeAppNeeded
}

/// Runtime string table: the bundled ui-strings.json carries every
/// language's partial table; missing keys fall back to English — the same
/// merge the TV app does with `{ ...EN, ...STRINGS[lang] }`.
struct Strings {
    let lang: String

    private static let tables: [String: [String: String]] = {
        guard
            let url = Bundle.main.url(forResource: "ui-strings", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONDecoder().decode(StringsFile.self, from: data)
        else { return [:] }
        return root.strings
    }()

    private static let allergens: [String: [String: String]] = {
        guard
            let url = Bundle.main.url(forResource: "ui-strings", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONDecoder().decode(StringsFile.self, from: data)
        else { return [:] }
        return root.allergens
    }()

    init(lang: String) { self.lang = lang }

    subscript(_ key: SKey) -> String {
        Strings.tables[lang]?[key.rawValue]
            ?? Strings.tables["en"]?[key.rawValue]
            ?? key.rawValue
    }

    /// Replace {placeholders} — e.g. stepOf "Step {n} of {t}".
    static func fill(_ s: String, _ vars: [String: CustomStringConvertible]) -> String {
        vars.reduce(s) { str, pair in
            str.replacingOccurrences(of: "{\(pair.key)}", with: pair.value.description)
        }
    }

    /// Localised allergen name; the API ships English-only codes.
    static func allergenName(lang: String, code: String) -> String {
        allergens[lang]?[code] ?? allergens["en"]?[code] ?? code
    }

    private struct StringsFile: Decodable {
        let strings: [String: [String: String]]
        let allergens: [String: [String: String]]
    }
}
