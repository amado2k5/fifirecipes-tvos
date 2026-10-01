import XCTest

/// Captures App Store / marketing screenshots (1920×1080) and attaches them
/// to the test result so they can be exported from the .xcresult bundle:
///
///   xcodebuild test -only-testing:FifiRecipesTVUITests/ScreenshotTests \
///     -resultBundlePath shots.xcresult
///   xcrun xcresulttool export attachments --path shots.xcresult \
///     --output-path docs/screenshots
///
/// Output names match site/index.html: home-en, recipe-en, kids-en, home-ar.
@MainActor
final class ScreenshotTests: XCTestCase {

    private let remote = XCUIRemote.shared

    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    /// Walk down the home screen pressing Select on each card until a
    /// recipe detail opens — robust against focus ordering changes.
    private func openRecipe(_ app: XCUIApplication) {
        for _ in 0..<14 {
            if el(app, "recipeDetail").exists { return }
            remote.press(.down)
            usleep(300_000)
            remote.press(.select)
            usleep(400_000)
        }
    }

    private func goToTab(_ app: XCUIApplication, index: Int) {
        for _ in 0..<8 { remote.press(.up); usleep(200_000) }
        for _ in 0..<6 { remote.press(.left); usleep(120_000) }
        for _ in 0..<index { remote.press(.right); usleep(150_000) }
        remote.press(.select)
        usleep(500_000)
    }

    /// Press down+select until the element appears (walks into grids).
    private func pressUntil(_ app: XCUIApplication, _ id: String, tries: Int = 20) -> Bool {
        for _ in 0..<tries {
            if el(app, id).exists { return true }
            remote.press(.down); usleep(300_000)
            remote.press(.select); usleep(400_000)
        }
        return el(app, id).exists
    }

    func testCaptureScreenshots() throws {
        // — English home —
        let app = XCUIApplication()
        app.launchArguments = ["-fifi.language", "en"]
        app.launch()
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 60))
        sleep(4) // let the first images settle
        snap(app, "home-en")

        // — English recipe detail —
        openRecipe(app)
        if el(app, "recipeDetail").waitForExistence(timeout: 40) {
            sleep(2)
            snap(app, "recipe-en")
            remote.press(.menu)
            XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 15))
        }

        // — Chapters —
        goToTab(app, index: 1)
        if el(app, "chaptersScreen").waitForExistence(timeout: 40) {
            sleep(2)
            snap(app, "chapters-en")
        }

        // — Search —
        goToTab(app, index: 2)
        if el(app, "searchScreen").waitForExistence(timeout: 40) {
            sleep(1)
            snap(app, "search-en")
        }

        // — Kids catalogue —
        goToTab(app, index: 3)
        if el(app, "kidsScreen").waitForExistence(timeout: 40) {
            sleep(2)
            snap(app, "kids-en")

            // — Kids cooking steps —
            if pressUntil(app, "kidsStepNext") {
                sleep(1)
                snap(app, "kids-steps-en")
            }
        }
    }

    func testCaptureRTL() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-fifi.language", "ar"]
        app.launch()
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 60))
        sleep(4)
        snap(app, "home-ar")
    }
}
