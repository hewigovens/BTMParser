//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

@testable import BTMParser
import XCTest

final class BTMParserTests: XCTestCase {
    func testParseValidBTMFile() throws {
        guard let btmFileURL = Bundle.module.url(forResource: "BackgroundItems-v13", withExtension: "btm", subdirectory: "Resources") else {
            throw XCTSkip("Test resource BackgroundItems-v13.btm not found in bundle.")
        }
        let btmFilePath = btmFileURL.path

        guard FileManager.default.fileExists(atPath: btmFilePath) else {
            XCTFail("Test BTM file not found at \(btmFilePath)")
            return
        }

        let parsedData: ParsedData = try BTMParser.parse(path: btmFileURL)

        XCTAssertEqual(parsedData.path, btmFilePath, "Path mismatch")
        XCTAssertNotNil(parsedData.itemsByUserID, "itemsByUserID should exist")

        // Use the typed dictionary directly
        let itemsByUserID = parsedData.itemsByUserID

        // Check for specific User ID (501 -> UUID: DCA7C5DA-F8EE-4910-A2F5-C32EDCAC43FC)
        let targetUserID = "DCA7C5DA-F8EE-4910-A2F5-C32EDCAC43FC"
        guard let userItems = itemsByUserID[targetUserID] else {
            XCTFail("Expected User ID \(targetUserID) not found in itemsByUserID")
            return
        }
        XCTAssertFalse(userItems.isEmpty, "User ID \(targetUserID) should have items")

        // Find Item #3 ("1Password Launcher") by its identifier
        let targetIdentifier = "4.com.1password.1password-launcher" // Correct identifier for Item #3
        guard let targetItem = userItems.first(where: { $0.identifier == targetIdentifier }) else { // Use .identifier
            XCTFail("Expected Item with identifier \(targetIdentifier) not found for user \(targetUserID)")
            return
        }

        // Assert specific values for Item #3 ("1Password Launcher") using struct properties
        XCTAssertEqual(targetItem.name, "1Password Launcher", "Item name mismatch")
        XCTAssertEqual(targetItem.uuid, "86703457-9137-4467-AF13-B21883C26467", "Item UUID mismatch")
        XCTAssertEqual(targetItem.developerName, "AgileBits Inc.", "Item developer name mismatch")
        XCTAssertEqual(targetItem.teamIdentifier, "2BUA8C4S2C", "Item team ID mismatch")
        XCTAssertEqual(targetItem.type, 4, "Item type mismatch") // Direct property access
        XCTAssertEqual(targetItem.typeDetails, "login item", "Item type details mismatch") // Direct property access
        // Update expected values based on actual decoded data from .btm file
        XCTAssertEqual(targetItem.disposition, 10, "Item disposition mismatch") // Direct property access
        XCTAssertEqual(targetItem.dispositionDetails, "disabled allowed visible notified", "Item disposition details mismatch") // Direct property access
        XCTAssertEqual(targetItem.bundleIdentifier, "com.1password.1password-launcher", "Item bundle ID mismatch")
        XCTAssertEqual(targetItem.containerIdentifier, "2.com.1password.1password", "Item container ID mismatch") // Check new property name
        XCTAssertEqual(targetItem.generation, 4, "Item generation mismatch") // Direct property access

        let expectedExeSuffix = "/Contents/MacOS/1Password Launcher"
        if let exePath = targetItem.executablePath { // Use .executablePath
            XCTAssertTrue(exePath.hasSuffix(expectedExeSuffix), "Item executable path mismatch (expected suffix: \(expectedExeSuffix), got: \(exePath))")
        } else {
            XCTFail("Item executable path is missing") // Adjusted fail message
        }
    }

    func testParseNonExistentFile() throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/to/non/existent/file.btm")

        // Expect a specific error when the file doesn't exist
        XCTAssertThrowsError(try BTMParser.parse(path: nonExistentURL)) { error in
            guard let btmError = error as? BTMParserError else {
                XCTFail("Expected BTMParserError but got \(type(of: error))")
                return
            }
            XCTAssertEqual(btmError, .fileNotFound(path: nonExistentURL.path),
                           "Expected .fileNotFound error for non-existent file.")
        }
    }
}
