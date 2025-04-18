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

        let itemsByUserID = parsedData.itemsByUserID

        // Check for specific User ID (501 -> UUID: DCA7C5DA-F8EE-4910-A2F5-C32EDCAC43FC)
        let targetUserID = "DCA7C5DA-F8EE-4910-A2F5-C32EDCAC43FC"
        guard let userItems = itemsByUserID[targetUserID] else {
            XCTFail("Expected User ID \(targetUserID) not found in itemsByUserID")
            return
        }
        XCTAssertFalse(userItems.isEmpty, "User ID \(targetUserID) should have items")

        let targetIdentifier = "4.com.1password.1password-launcher"
        guard let targetItem = userItems.first(where: { $0.identifier == targetIdentifier }) else {
            XCTFail("Expected Item with identifier \(targetIdentifier) not found for user \(targetUserID)")
            return
        }

        XCTAssertEqual(targetItem.name, "1Password Launcher")
        XCTAssertEqual(targetItem.uuid, "B3A2C9E2-7993-4C73-A23C-F215C413A2AD")
        XCTAssertEqual(targetItem.developerName, "AgileBits Inc.")
        XCTAssertEqual(targetItem.teamIdentifier, "2BUA8C4S2C")
        XCTAssertEqual(targetItem.type, 4)
        XCTAssertEqual(targetItem.typeDetails, "login item")
        // Update expected values based on actual decoded data from .btm file
        XCTAssertEqual(targetItem.disposition, 2)
        XCTAssertEqual(targetItem.dispositionDetails, "disabled allowed visible not notified")
        XCTAssertEqual(targetItem.bundleIdentifier, "com.1password.1password-launcher")
        XCTAssertEqual(targetItem.containerIdentifier, "2.com.1password.1password")
        XCTAssertEqual(targetItem.generation, 1)
    }

    func testParseNonExistentFile() throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/to/non/existent/file.btm")

        // Expect a specific error when the file doesn't exist
        XCTAssertThrowsError(try BTMParser.parse(path: nonExistentURL)) { error in
            guard let btmError = error as? BTMParserError else {
                XCTFail("Expected BTMParserError but got \(type(of: error))")
                return
            }
            XCTAssertEqual(btmError, .fileNotFound(path: nonExistentURL.path))
        }
    }
}
