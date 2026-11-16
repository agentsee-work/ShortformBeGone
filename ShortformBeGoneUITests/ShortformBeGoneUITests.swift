//
//  ShortformBeGoneUITests.swift
//  ShortformBeGoneUITests
//
//  Walks every screen. When SCREENSHOT_DIR is set (pass it to xcodebuild as
//  TEST_RUNNER_SCREENSHOT_DIR), each screen is also saved there as a PNG,
//  which is how the App Store screenshots are made: see tools/screenshots.sh.
//

import XCTest

final class ShortformBeGoneUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(demoState: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoState", demoState, "-resetSetupProgress", "YES"]
        app.launch()
        return app
    }

    /// iPhone has a tab bar; iPad shows the tabs as plain buttons at the top.
    @MainActor
    private func openTab(_ name: String, in app: XCUIApplication) {
        let inTabBar = app.tabBars.buttons[name]
        if inTabBar.exists {
            inTabBar.tap()
        } else {
            app.buttons[name].firstMatch.tap()
        }
    }

    @MainActor
    private func snapshot(_ name: String) {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !directory.isEmpty else { return }
        let url = URL(fileURLWithPath: directory).appendingPathComponent(name + ".png")
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
    }

    @MainActor
    func testWalkthroughWhenFilterIsActive() throws {
        let app = launch(demoState: "active")

        XCTAssertTrue(app.staticTexts["Short-form video is blocked"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Open the setup guide"].exists)
        snapshot("1-status")

        openTab("Rules", in: app)
        XCTAssertTrue(app.staticTexts["tiktok.com"].waitForExistence(timeout: 5))
        let field = app.textFields["test-address"]
        field.tap()
        field.typeText("youtube.com/watch?v=abc")
        XCTAssertTrue(app.staticTexts["Allowed"].waitForExistence(timeout: 5))

        let entered = "youtube.com/watch?v=abc"
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: entered.count))
        field.typeText("m.youtube.com/shorts/abc\n") // return dismisses the keyboard, which covers the tab bar
        XCTAssertTrue(app.staticTexts["Blocked"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["by rule youtube.com/shorts"].exists)
        snapshot("2-rules-blocked")

        openTab("Setup", in: app)
        XCTAssertTrue(app.staticTexts["Supervise this device"].waitForExistence(timeout: 5))
        snapshot("3-setup")

        let profileStep = app.staticTexts["Install the profile"]
        if !profileStep.isHittable { app.swipeUp() }
        profileStep.tap()
        XCTAssertTrue(app.buttons["Send the download link to your Mac"].waitForExistence(timeout: 5))
        snapshot("4-install-profile")

        let done = app.switches["I have done this step"]
        // The toggle is the last row; a short screen needs more than one swipe to reach it.
        for _ in 0..<6 where !(done.exists && done.isHittable) { app.swipeUp() }
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.switches.firstMatch.tap()
        XCTAssertEqual(done.value as? String, "1")
        // The back button sits in the navigation bar, or beside the content on a wide iPhone.
        let back = app.navigationBars.buttons.firstMatch
        if back.exists { back.tap() } else { app.buttons["BackButton"].firstMatch.tap() }
        // The step's row now reads "Done" in place of its number.
        let doneRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Done' AND label CONTAINS 'Install the profile'")).firstMatch
        XCTAssertTrue(doneRow.waitForExistence(timeout: 5))
    }

    @MainActor
    func testNotSetUpPointsToTheSetupGuide() throws {
        let app = launch(demoState: "notInstalled")

        XCTAssertTrue(app.staticTexts["Not set up yet"].waitForExistence(timeout: 10))
        snapshot("5-not-set-up")
        let openGuide = app.buttons["Open the setup guide"]
        for _ in 0..<4 where !(openGuide.exists && openGuide.isHittable) { app.swipeUp() }
        openGuide.tap()
        XCTAssertTrue(app.staticTexts["Switch on the Safari blocker"].waitForExistence(timeout: 5))

        app.swipeUp()
        app.staticTexts["About and privacy"].tap()
        // Version is the last row, below the fold on a short screen.
        let version = app.staticTexts["Version"]
        for _ in 0..<4 where !version.exists { app.swipeUp() }
        XCTAssertTrue(version.waitForExistence(timeout: 5))
    }
}
