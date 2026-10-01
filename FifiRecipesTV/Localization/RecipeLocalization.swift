import Foundation

/// View-ready projection of a RecipeFile — a direct port of the `localize()`
/// in the TV app's RecipeScreen, including its hard-won fallback rules:
///
///   * `ar`: master recipe.* fields are Arabic; translations.ar is empty by
///     design, so Arabic falls back to the master fields, never English.
///   * steps: prefer the language's instruction text; else `ui.textEn` for
///     non-Arabic, `ui.text` for Arabic.
///   * culturalNotes: show ONLY the requested language's note — never fall
///     back to English; the card is hidden when absent.
enum RecipeLocalization {

    struct Localized {
        let title: String
        let subtitle: String?
        let chapter: String?
        let category: String?
        let cookingMethod: String?
        let prepTime: String?
        let cookTime: String?
        let servings: String?
        let culturalNotes: String?
        let ingredients: [Ingredient]
        let steps: [Step]
    }

    struct Ingredient: Equatable {
        let name: String
        let amount: String?
    }

    struct Step: Equatable {
        let n: Int
        let text: String
        let phase: String?
        let alternative: String?
        let isTip: Bool
    }

    private enum MetaKey { case title, chapter, category, cookingMethod, prepTime, cookTime, servings }

    static func localize(_ file: RecipeFile, lang: String) -> Localized {
        let r = file.recipe
        let t = file.translations[lang] ?? RecipeTranslation(
            title: nil, chapter: nil, category: nil, cookingMethod: nil,
            prepTime: nil, cookTime: nil, servings: nil, culturalNotes: nil,
            ingredients: nil, instructions: nil)
        let en = file.translations["en"]

        func pick(_ k: MetaKey) -> String? {
            let tr = value(t, k)
            let master = value(r, k)
            if let tr { return tr }
            if lang == "ar" { return master }
            return en.flatMap { value($0, k) } ?? master
        }

        let trIng = t.ingredients ?? (lang == "ar" ? [:] : en?.ingredients ?? [:])
        let trIns = t.instructions ?? (lang == "ar" ? [:] : en?.instructions ?? [:])

        let title = pick(.title) ?? r.title

        return Localized(
            title: title,
            subtitle: r.titleEn != title ? r.titleEn : nil,
            chapter: pick(.chapter) ?? r.chapter,
            category: pick(.category) ?? r.category,
            cookingMethod: pick(.cookingMethod) ?? r.cookingMethod,
            prepTime: pick(.prepTime) ?? r.prepTime,
            cookTime: pick(.cookTime) ?? r.cookTime,
            servings: pick(.servings) ?? r.servings,
            culturalNotes: t.culturalNotes,
            ingredients: r.masterIngredients.map { mi in
                Ingredient(
                    name: trIng[mi.id]?.name ?? mi.name,
                    // A missing translated amount falls back to English, not Arabic.
                    amount: trIng[mi.id]?.standardAmount
                        ?? (lang == "ar" ? nil : en?.ingredients?[mi.id]?.standardAmount)
                        ?? mi.standardAmount)
            },
            steps: r.uniqueInstructions.map { ui in
                Step(
                    n: ui.stepNumber,
                    text: trIns[String(ui.stepNumber)]
                        ?? (lang == "ar" ? ui.text : ui.textEn ?? ui.text),
                    phase: ui.phase,
                    alternative: (ui.isAlternative ?? false) ? (ui.alternativeLabel ?? "alternative") : nil,
                    isTip: ui.importance == "tip")
            })
    }

    private static func value(_ t: RecipeTranslation, _ k: MetaKey) -> String? {
        switch k {
        case .title: return t.title
        case .chapter: return t.chapter
        case .category: return t.category
        case .cookingMethod: return t.cookingMethod
        case .prepTime: return t.prepTime
        case .cookTime: return t.cookTime
        case .servings: return t.servings
        }
    }

    private static func value(_ r: RecipeCore, _ k: MetaKey) -> String? {
        switch k {
        case .title: return r.title
        case .chapter: return r.chapter
        case .category: return r.category
        case .cookingMethod: return r.cookingMethod
        case .prepTime: return r.prepTime
        case .cookTime: return r.cookTime
        case .servings: return r.servings
        }
    }
}
