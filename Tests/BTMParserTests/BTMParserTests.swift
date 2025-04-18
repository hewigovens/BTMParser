//  Copyright © 2023 Objective-See
//  Copyright © 2025 Tao Xu
//  SPDX‑License‑Identifier: GPL-3.0-or-later

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

        let parsedData = try BTMParser.parse(path: btmFileURL)

        XCTAssertNotNil(parsedData, "Parsing should return a non-nil dictionary.")
        XCTAssertEqual(parsedData[Keys.path] as? String, btmFilePath, "Path key mismatch")
        XCTAssertNil(parsedData[Keys.error], "Error key should be nil on success")
        XCTAssertNotNil(parsedData[Keys.itemsByUserID], "Expected 'itemsByUserID' key not found.")

        // Check itemsByUserID structure
        guard let itemsByUserID = parsedData[Keys.itemsByUserID] as? [String: [[String: Any]]] else {
            XCTFail("itemsByUserID key is missing or not the expected type [String: [[String: Any]]]")
            return
        }

        // Check for specific User ID (501 -> UUID: DCA7C5DA-F8EE-4910-A2F5-C32EDCAC43FC)
        let targetUserID = "DCA7C5DA-F8EE-4910-A2F5-C32EDCAC43FC"
        guard let userItems = itemsByUserID[targetUserID] else {
            XCTFail("Expected User ID \(targetUserID) not found in itemsByUserID")
            return
        }
        XCTAssertFalse(userItems.isEmpty, "User ID \(targetUserID) should have items")

        // Find Item #3 ("1Password Launcher") by its identifier
        let targetIdentifier = "4.com.1password.1password-launcher" // Correct identifier for Item #3
        guard let targetItem = userItems.first(where: { $0[Keys.itemID] as? String == targetIdentifier }) else {
            XCTFail("Expected Item with identifier \(targetIdentifier) not found for user \(targetUserID)")
            return
        }

        // Assert specific values for Item #3 ("1Password Launcher")
        XCTAssertEqual(targetItem[Keys.itemName] as? String, "1Password Launcher", "Item name mismatch")
        XCTAssertEqual(targetItem[Keys.itemUUID] as? String, "86703457-9137-4467-AF13-B21883C26467", "Item UUID mismatch")
        XCTAssertEqual(targetItem[Keys.itemDevName] as? String, "AgileBits Inc.", "Item developer name mismatch")
        XCTAssertEqual(targetItem[Keys.itemTeamID] as? String, "2BUA8C4S2C", "Item team ID mismatch")
        XCTAssertEqual(targetItem[Keys.itemType] as? Int64, 4, "Item type mismatch")
        XCTAssertEqual(targetItem[Keys.itemTypeDetails] as? String, "login item", "Item type details mismatch")
        // Update expected values based on actual decoded data from .btm file
        XCTAssertEqual(targetItem[Keys.itemDisposition] as? Int64, 10, "Item disposition mismatch") // Actual decoded value is 10 (0xa)
        XCTAssertEqual(targetItem[Keys.itemDispositionDetails] as? String, "disabled allowed visible notified", "Item disposition details mismatch") // Matches disposition 10
        XCTAssertEqual(targetItem[Keys.itemBundleID] as? String, "com.1password.1password-launcher", "Item bundle ID mismatch")
        XCTAssertEqual(targetItem[Keys.itemContainer] as? String, "2.com.1password.1password", "Item parent ID mismatch")
        XCTAssertEqual(targetItem[Keys.itemGeneration] as? Int64, 4, "Item generation mismatch") // Actual decoded value is 4

        let expectedExeSuffix = "/Contents/MacOS/1Password Launcher"
        if let exePath = targetItem[Keys.itemExePath] as? String {
            XCTAssertTrue(exePath.hasSuffix(expectedExeSuffix), "Item executable path mismatch (expected suffix: \(expectedExeSuffix), got: \(exePath))")
        } else {
            XCTFail("Item executable path is missing or not a string")
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
