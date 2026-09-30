import SwiftUI
import UIKit

/// Per-language typeface selection, mirroring the TV app's font stack:
///   Latin default        → Plus Jakarta Sans
///   RTL default (ar/ps)  → Tajawal
///   fa                   → Vazirmatn
///   ur                   → Noto Nastaliq Urdu (tall Nastaliq line height)
///   he                   → Heebo
///   kids mode            → Baloo 2 / Baloo Bhaijaan 2 (kids-RTL) / Heebo (he)
///
/// Base point sizes come from `UIFont.preferredFont(forTextStyle:)`, so the
/// bundled faces land at the platform's 10-foot scale (tvOS body ≈ 29 pt,
/// not the iOS ~17 pt) while still scaling via `relativeTo:`. If a bundled
/// face is missing we fall back to the system font rather than crashing.
enum FifiFonts {
    enum Weight {
        case regular, medium, bold, heavy
    }

    static let rtlLanguages: Set<String> = ["ar", "ur", "fa", "ps", "he", "ku"]

    static func family(lang: String, kids: Bool) -> String {
        if kids {
            if lang == "he" { return "Heebo" }
            return rtlLanguages.contains(lang) ? "BalooBhaijaan2" : "Baloo2"
        }
        switch lang {
        case "ur": return "NotoNastaliqUrdu"
        case "fa": return "Vazirmatn"
        case "he": return "Heebo"
        case let l where rtlLanguages.contains(l): return "Tajawal"
        default: return "PlusJakartaSans"
        }
    }

    /// Weight → PostScript suffix, per bundled face set.
    private static func suffix(family: String, weight: Weight) -> String {
        switch family {
        case "Baloo2", "BalooBhaijaan2":
            switch weight {
            case .regular: return "Regular"
            case .medium: return "SemiBold"
            case .bold, .heavy: return "ExtraBold"
            }
        case "Vazirmatn", "Heebo":
            switch weight {
            case .regular: return "Regular"
            case .medium: return "Medium"
            case .bold, .heavy: return "Bold"
            }
        case "NotoNastaliqUrdu":
            return weight == .regular || weight == .medium ? "Regular" : "Bold"
        default: // PlusJakartaSans, Tajawal
            switch weight {
            case .regular: return "Regular"
            case .medium: return "Medium"
            case .bold: return "Bold"
            case .heavy: return "ExtraBold"
            }
        }
    }

    /// The bundled files' PostScript names (from scripts/fetch-fonts.py output).
    static func postScriptName(lang: String, kids: Bool, weight: Weight) -> String? {
        let fam = family(lang: lang, kids: kids)
        let candidate = "\(fam)-\(suffix(family: fam, weight: weight))"
        return UIFont(name: candidate, size: 12) != nil ? candidate : nil
    }

    static func font(
        lang: String, kids: Bool = false,
        style: Font.TextStyle = .body, weight: Weight = .regular
    ) -> Font {
        if let name = postScriptName(lang: lang, kids: kids, weight: weight) {
            return .custom(name, size: baseSize(for: style), relativeTo: style)
        }
        let w: Font.Weight = {
            switch weight {
            case .regular: return .regular
            case .medium: return .medium
            case .bold: return .bold
            case .heavy: return .heavy
            }
        }()
        return .system(style, weight: w)
    }

    /// Platform-native point size for each text style — on tvOS these resolve
    /// to the larger 10-foot defaults (e.g. body 29, title 76).
    private static func baseSize(for style: Font.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: uiStyle(for: style)).pointSize
    }

    private static func uiStyle(for style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: return .title1 // no .largeTitle text style on tvOS
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

private struct FifiLanguageKey: EnvironmentKey {
    static let defaultValue = "en"
}

private struct FifiKidsFontKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var fifiLanguage: String {
        get { self[FifiLanguageKey.self] }
        set { self[FifiLanguageKey.self] = newValue }
    }
    var fifiKidsFont: Bool {
        get { self[FifiKidsFontKey.self] }
        set { self[FifiKidsFontKey.self] = newValue }
    }
}

struct FifiFontModifier: ViewModifier {
    @Environment(\.fifiLanguage) private var lang
    @Environment(\.fifiKidsFont) private var kids
    let style: Font.TextStyle
    let weight: FifiFonts.Weight

    func body(content: Content) -> some View {
        content
            .font(FifiFonts.font(lang: lang, kids: kids, style: style, weight: weight))
            // Nastaliq needs generous leading, same as the TV CSS (lh 2.1).
            .lineSpacing(FifiFonts.family(lang: lang, kids: kids) == "NotoNastaliqUrdu" ? 18 : 0)
    }
}

extension View {
    func fifiFont(_ style: Font.TextStyle = .body, weight: FifiFonts.Weight = .regular) -> some View {
        modifier(FifiFontModifier(style: style, weight: weight))
    }

    /// Scopes kids-mode fonts (Baloo faces) to a subtree.
    func kidsFontScope() -> some View {
        environment(\.fifiKidsFont, true)
    }
}
