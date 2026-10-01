import XCTest

/// UI tests run against the live fifi.cooking API (the product is
/// online-only); the offline test points the client at a dead origin via
/// the -fifi.apiOrigin launch override.
///
/// tvOS has no tap gestures — every interaction is a Siri Remote press via
/// XCUIRemote, which also exercises the focus engine end-to-end. Focus is
/// detected by reading the *focused element's identifier*; reading
/// `hasFocus`/`frame` on an element whose query transiently matches nothing
/// records a snapshot failure, so we never do that mid-navigation.
@MainActor
final class FifiRecipesTVUITests: XCTestCase {

    private let remote = XCUIRemote.shared

    private func launch(
        _ app: XCUIApplication, lang: String? = nil, apiOrigin: String? = nil
    ) {
        app.launchArguments += ["-fifi.reset", "1"]
        if let lang { app.launchArguments += ["-fifi.language", lang] }
        if let apiOrigin { app.launchArguments += ["-fifi.apiOrigin", apiOrigin] }
        app.launch()
    }

    /// Identifiers are placed on ScrollViews and container views, so query
    /// every element type rather than just `otherElements`.
    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    /// The currently focused element itself (for geometry).
    private func focused(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true"))
            .firstMatch
    }

    /// Blind navigation is more reliable on tvOS than steering by element
    /// geometry: press `dir` then Select, and stop as soon as the element
    /// identified by `id` exists. Selecting a non-destination element along
    /// the way (a filter chip, a tick row) is harmless.
    @discardableResult
    private func pressUntil(_ app: XCUIApplication, _ id: String,
                            tries: Int = 14) -> Bool {
        for _ in 0..<tries {
            if el(app, id).exists { return true }
            remote.press(.down)
            usleep(300_000)
            remote.press(.select)
            usleep(300_000)
        }
        return el(app, id).exists
    }

    /// Press Select until the element identified by `id` exists — used to
    /// walk the kids step-by-step flow where the Next button keeps focus.
    private func selectUntil(_ app: XCUIApplication, _ id: String,
                             tries: Int = 24) -> Bool {
        for _ in 0..<tries {
            if el(app, id).exists { return true }
            remote.press(.select)
            usleep(400_000)
        }
        return el(app, id).exists
    }

    /// Switch to a top tab by walking focus up to the tab bar then across.
    private func goToTab(_ app: XCUIApplication, index: Int) {
        for _ in 0..<8 {
            let cur = focused(app)
            if cur.exists && cur.frame.midY < 150 { break }
            remote.press(.up)
            usleep(200_000)
        }
        for _ in 0..<6 { remote.press(.left); usleep(120_000) }
        for _ in 0..<index { remote.press(.right); usleep(150_000) }
        remote.press(.select)
    }

    // MARK: first-run picker → home

    func testFirstRunLanguagePickerThenHome() throws {
        let app = XCUIApplication()
        launch(app)

        let picker = el(app, "languagePicker")
        XCTAssertTrue(picker.waitForExistence(timeout: 30))

        // Focus lands on the first tile; press Right until English holds
        // focus (language order puts ar first, en second).
        for _ in 0..<8 where focusedId(app) != "lang-en" {
            remote.press(.right)
            usleep(250_000)
        }
        XCTAssertEqual(focusedId(app), "lang-en")
        remote.press(.select)

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 40))
    }

    private func focusedId(_ app: XCUIApplication) -> String {
        let f = focused(app)
        return f.exists ? f.identifier : ""
    }

    // MARK: home → recipe detail → back

    func testHomeRailOpensRecipe() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 90))
        // Cards render after the feed fetch — wait for one before pressing,
        // otherwise early presses are swallowed while the screen is empty.
        XCTAssertTrue(el(app, "heroCard").waitForExistence(timeout: 90))

        // Walk down the screen pressing Select on each card until the recipe
        // detail appears — hero or rail card, either one pushes a recipe.
        XCTAssertTrue(pressUntil(app, "recipeDetail", tries: 30),
                      "no card opened a recipe")

        // Menu (back) returns home.
        remote.press(.menu)
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 30))
    }

    // MARK: RTL smoke — Arabic mirrors the layout

    func testArabicRTLLayout() throws {
        let app = XCUIApplication()
        launch(app, lang: "ar")
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 90))

        // In RTL the first tab (الرئيسية = Home) sits at the trailing (right)
        // edge — its x position should be right of center, not left.
        let homeTab = app.buttons["الرئيسية"].firstMatch
        XCTAssertTrue(homeTab.waitForExistence(timeout: 30))
        let screenMid = app.windows.firstMatch.frame.midX
        XCTAssertGreaterThan(homeTab.frame.midX, screenMid,
                             "RTL: first tab should sit on the right half")
    }

    // MARK: kids flow end-to-end

    func testKidsFlowEndToEnd() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 40))
        goToTab(app, index: 3) // Kids tab

        XCTAssertTrue(el(app, "kidsScreen").waitForExistence(timeout: 90))
        // Wait for the catalogue to render before pressing — early remote
        // presses are swallowed while the grid is still empty.
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'kidsCard-'"))
            .firstMatch.waitForExistence(timeout: 90))

        // Pressing down through the filter chips reaches the card grid;
        // selecting any card opens the ready screen (its landmark is the
        // Let's cook button).
        XCTAssertTrue(pressUntil(app, "kidsStartCooking", tries: 30),
                      "no kids card opened the ready screen")

        // Keep walking down past the tickable ingredients to Let's cook.
        XCTAssertTrue(pressUntil(app, "kidsStepNext", tries: 30),
                      "Let's cook never opened the step flow")

        // Focus lands on Next via defaultFocus — pressing Select walks
        // through every step to the celebration screen.
        XCTAssertTrue(selectUntil(app, "kidsCookAgain"),
                      "step flow never reached the celebration")
    }

    // MARK: search

    func testSearchTabShowsSearchField() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 40))
        goToTab(app, index: 2) // Search tab

        XCTAssertTrue(el(app, "searchScreen").waitForExistence(timeout: 30))
        // The system search field is present in the navigation area.
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 20))
    }

    // MARK: offline → retry

    func testOfflineShowsErrorWithRetry() throws {
        let app = XCUIApplication()
        launch(app, apiOrigin: "http://127.0.0.1:1")
        let error = el(app, "errorScreen")
        XCTAssertTrue(error.waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["retryButton"].exists)
    }
}
