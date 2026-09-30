import XCTest
@testable import FifiRecipesTV

final class StringsTests: XCTestCase {

    private var table: [String: [String: String]] = [:]

    override func setUpWithError() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "ui-strings", withExtension: "json"))
        let root = try JSONDecoder().decode(Root.self, from: Data(contentsOf: url))
        table = root.strings
    }

    private struct Root: Decodable {
        let strings: [String: [String: String]]
        let allergens: [String: [String: String]]
    }

    func testAllTwentyFourLanguagesPresent() {
        XCTAssertEqual(table.count, 24)
        for code in ["ar", "en", "fr", "es", "ja", "hi", "pt", "ru", "zh", "de",
                     "it", "el", "ur", "fa", "tr", "ku", "id", "sw", "ko", "nl",
                     "ps", "he", "pl", "sv"] {
            XCTAssertNotNil(table[code], "missing language \(code)")
        }
    }

    func testEnglishIsComplete() {
        for key in SKey.allCases {
            XCTAssertNotNil(table["en"]?[key.rawValue], "en missing \(key.rawValue)")
        }
    }

    func testLookupFallsBackToEnglish() {
        // de has no appName — falls back to the English master value.
        XCTAssertEqual(Strings(lang: "de")[.appName], "FiFi Recipes")
        XCTAssertEqual(Strings(lang: "ar")[.appName], "وصفات فيفي")
        XCTAssertEqual(Strings(lang: "de")[.home], "Start")
        // Unknown language code → pure English.
        XCTAssertEqual(Strings(lang: "xx")[.home], "Home")
        // Unknown key → raw key name (never empty).
        XCTAssertFalse(Strings(lang: "en")[.letsCook].isEmpty)
    }

    func testFillPlaceholders() {
        XCTAssertEqual(
            Strings.fill("Step {n} of {t}", ["n": 2, "t": 5]),
            "Step 2 of 5")
    }

    // MARK: allergen map

    func testAllergenNamesLocalize() {
        XCTAssertEqual(Strings.allergenName(lang: "ar", code: "eggs"), "بيض")
        XCTAssertEqual(Strings.allergenName(lang: "fr", code: "milk"), "lait")
        XCTAssertEqual(Strings.allergenName(lang: "he", code: "nuts"), "אגוזים")
        // Missing language → English; unknown code → raw code.
        XCTAssertEqual(Strings.allergenName(lang: "xx", code: "nuts"), "tree nuts")
        XCTAssertEqual(Strings.allergenName(lang: "en", code: "quinoa"), "quinoa")
    }
}
