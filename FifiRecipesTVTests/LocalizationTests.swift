import XCTest
@testable import FifiRecipesTV

/// The localize() rules ported from the TV app — these encode real fixes:
/// ar master fallback, never-English cultural notes, instruction precedence.
final class LocalizationTests: XCTestCase {

    private var file: RecipeFile!

    override func setUpWithError() throws {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "recipe.sample", withExtension: "json"))
        file = try JSONDecoder().decode(RecipeFile.self, from: Data(contentsOf: url))
    }

    func testFixtureDecodes() {
        XCTAssertEqual(file.recipe.id, "test-recipe")
        XCTAssertEqual(file.recipe.masterIngredients.count, 2)
        XCTAssertEqual(file.recipe.uniqueInstructions.count, 4)
        XCTAssertEqual(file.estimate?.kcal, 250)
    }

    // MARK: ar master fallback — translations.ar is empty by design

    func testArabicUsesMasterFieldsNotEnglish() {
        let l = RecipeLocalization.localize(file, lang: "ar")
        XCTAssertEqual(l.title, "وصفة اختبار")
        XCTAssertEqual(l.chapter, "الفصل الأول")
        XCTAssertEqual(l.prepTime, "١٠ دقائق")
        XCTAssertEqual(l.subtitle, "Test Dish") // titleEn shown when it differs
        XCTAssertEqual(l.ingredients[0].name, "دقيق")
        XCTAssertEqual(l.steps[0].text, "اخلط المكونات") // ui.text, not textEn
        XCTAssertNil(l.culturalNotes)
    }

    // MARK: en translation preferred

    func testEnglishUsesTranslation() {
        let l = RecipeLocalization.localize(file, lang: "en")
        XCTAssertEqual(l.title, "Test Dish EN")
        XCTAssertEqual(l.subtitle, "Test Dish") // titleEn differs → shown
        XCTAssertEqual(l.ingredients[0].name, "Flour")
        XCTAssertEqual(l.ingredients[0].amount, "2 cups")
        XCTAssertEqual(l.ingredients[1].name, "سكر") // untranslated → master
        XCTAssertEqual(l.steps[0].text, "Mix all ingredients") // trIns override
        XCTAssertEqual(l.steps[1].text, "Bake") // missing trIns → textEn
        XCTAssertEqual(l.culturalNotes, "A note from Fatma")
    }

    // MARK: other languages fall back through en → master

    func testFrenchFallbackChain() {
        let l = RecipeLocalization.localize(file, lang: "fr")
        XCTAssertEqual(l.title, "Plat test")
        XCTAssertEqual(l.ingredients[0].name, "Farine")
        XCTAssertEqual(l.ingredients[1].name, "سكر") // fr/en both lack i2 → master
        XCTAssertEqual(l.steps[0].text, "Mix all ingredients") // en instructions
        XCTAssertEqual(l.steps[1].text, "Bake")
    }

    // MARK: cultural notes never fall back to English

    func testCulturalNotesNeverFallBack() {
        XCTAssertNotNil(RecipeLocalization.localize(file, lang: "en").culturalNotes)
        for lang in ["fr", "de", "ja", "sw", "ar"] {
            XCTAssertNil(
                RecipeLocalization.localize(file, lang: lang).culturalNotes,
                "\(lang) must not show the English note")
        }
    }

    // MARK: step metadata

    func testStepMetadata() {
        let l = RecipeLocalization.localize(file, lang: "en")
        XCTAssertNil(l.steps[0].alternative)
        XCTAssertEqual(l.steps[2].alternative, "بالعجان") // label passes through
        XCTAssertFalse(l.steps[0].isTip)
        XCTAssertTrue(l.steps[3].isTip)
    }
}
