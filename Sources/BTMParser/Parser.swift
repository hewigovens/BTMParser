//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// Parses the BTM (Background Task Management) database using pure Swift.
/// - Parameter btmPath: An optional URL pointing to a specific BTM database file. If nil, the default system path is used.
/// - Returns: A dictionary representing the parsed BTM data, or nil on failure.
/// - Throws: `BTMParserError` if the file is not found or parsing fails.
public func parse(path btmPath: URL) throws -> [String: Any] {
    var resultDict: [String: Any] = [:]
    resultDict[Keys.path] = btmPath.path

    // Check if file exists before attempting to read
    guard FileManager.default.fileExists(atPath: btmPath.path) else {
        throw BTMParserError.fileNotFound(path: btmPath.path)
    }

    do {
        // 1. Read Data
        let data = try Data(contentsOf: btmPath)

        // 2. Unarchive Data using helper
        let storage = try _unarchiveBTMData(data: data)

        // 3. Process the decoded Storage object
        return processStorage(storage, path: btmPath)

    } catch let error as BTMParserError {
        throw error
    } catch {
        throw BTMParserError.parsingFailed(reason: "Failed during file read or unarchiving for \(btmPath.path): \(error.localizedDescription)")
    }
}

// Private helper to handle NSKeyedUnarchiver logic
private func _unarchiveBTMData(data: Data) throws -> Storage {
    do {
        // Allowed classes for unarchiving - Ensure ItemRecord and Storage are included
        let allowedClasses: [AnyClass] = [
            Storage.self,
            ItemRecord.self,
            NSDictionary.self,
            NSArray.self,
            NSSet.self,
            NSString.self,
            NSNumber.self,
            NSDate.self,
            NSURL.self,
            NSUUID.self // Include NSUUID as UUID is decoded as this
        ]

        // Initialize unarchiver
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true // Enforce secure coding

        // Attempt to decode the root 'Storage' object using the 'store' key
        guard let storage = unarchiver.decodeObject(of: allowedClasses, forKey: "store") as? Storage else {
            print("Error: Failed to decode root 'Storage' object from BTM data using 'store' key.")
            throw BTMParserError.parsingFailed(reason: "Failed to decode root Storage object")
        }

        // Check for decoding errors
        if let decodingError = unarchiver.error {
            print("Error during unarchiving: \(decodingError.localizedDescription)")
            throw BTMParserError.parsingFailed(reason: "Unarchiving failed: \(decodingError.localizedDescription)")
        }

        // Finish decoding (redundant after checking error? Check Apple docs)
        unarchiver.finishDecoding()
        print("Decoded Storage object using 'store' key.")

        return storage
    } catch let error as BTMParserError {
        throw error
    } catch {
        throw BTMParserError.parsingFailed(reason: "Unarchiving setup failed: \(error.localizedDescription)")
    }
}

// Helper function to process the decoded Storage object
private func processStorage(_ storage: Storage, path: URL) -> [String: Any] {
    var contents: [String: Any] = [:]
    contents[Keys.path] = path.path

    // Process itemsByUserIdentifier
    // The dictionary seems to be [String: NSArray], where NSArray contains ItemRecord objects
    if let itemsDict = storage.itemsByUserIdentifier as? [String: NSArray] {
        var processedItemsByUserID: [String: [[String: Any]]] = [:]
        for (userID, recordsArray) in itemsDict {
            // Ensure recordsArray contains ItemRecord objects
            guard let records = recordsArray as? [ItemRecord] else {
                print("Warning: Could not cast records array for user ID \(userID) to [ItemRecord]")
                continue
            }
            // TODO: Convert userID (UUID string) to actual UID if needed (like uidFromUUID)
            processedItemsByUserID[userID] = records.map { record in
                // Pass the context (all records for this user) for parent lookup
                itemRecordToDictionary(record, allItemsForUser: records)
            }
        }
        contents[Keys.itemsByUserID] = processedItemsByUserID
    } else if storage.itemsByUserIdentifier != nil {
        print("Warning: Could not cast itemsByUserIdentifier to [String: NSArray] containing ItemRecords. Actual type: \(type(of: storage.itemsByUserIdentifier!))")
        if let dict = storage.itemsByUserIdentifier {
            for (key, value) in dict {
                print("  Key: \(key), Value Type: \(type(of: value))")
                if let arr = value as? NSArray {
                    print("    Array count: \(arr.count)")
                    if arr.count > 0 {
                        print("    First item type: \(type(of: arr[0]))")
                    }
                }
            }
        }
    }

    // Process mdmPayloadsByIdentifier
    if let mdmDict = storage.mdmPayloadsByIdentifier as? [String: Any], !mdmDict.isEmpty {
        // Note: Original ObjC code seemed to have a bug here, assigning itemsByUserIdentifier again.
        // Assigning the actual mdmPayloadsByIdentifier here.
        contents[Keys.mdmPayload] = mdmDict
    }

    return contents
}

// Helper function to convert ItemRecord to Dictionary
// Needs context of all items for the same user to find parents
private func itemRecordToDictionary(_ record: ItemRecord, allItemsForUser: [ItemRecord]) -> [String: Any] {
    var item: [String: Any] = [:]

    // Basic properties
    item[Keys.itemUUID] = record.uuid
    item[Keys.itemName] = record.name
    item[Keys.itemDevName] = record.developerName
    if let teamID = record.teamIdentifier, !teamID.isEmpty { // Check if nil or empty
        item[Keys.itemTeamID] = teamID
    }
    // Add raw type and disposition values
    item[Keys.itemType] = record.type
    item[Keys.itemDisposition] = record.disposition

    // Details derived from helper functions
    item[Keys.itemTypeDetails] = TypeFlag.typeDetails(record)
    item[Keys.itemDispositionDetails] = DispositionFlag.dispositionDetails(record)

    item[Keys.itemID] = record.identifier
    // Convert NSURL to String for JSON compatibility
    item[Keys.itemURL] = record.url?.absoluteString
    item[Keys.itemExePath] = record.executablePath // Initial value
    item[Keys.itemGeneration] = record.generation
    if let bundleID = record.bundleIdentifier, !bundleID.isEmpty {
        item[Keys.itemBundleID] = bundleID
    }

    // Associated bundle IDs
    // Original ObjC uses NSArray, convert to Swift [String]? for consistency
    if let associated = record.associatedBundleIdentifiers as? [String], !associated.isEmpty {
        item[Keys.itemAssociatedIDs] = associated
    }

    // Parent ID
    if let parent = findParent(record, items: allItemsForUser) {
        let parentID = parent.identifier ?? "<Parent ID Missing>"
        item[Keys.itemContainer] = parentID
    } else if let containerID = record.container, !containerID.isEmpty {
        // If parent object not found but container ID exists, use the raw container ID
        item[Keys.itemContainer] = containerID
    }

    // Embedded item IDs
    if let embedded = record.embeddedItems?.allObjects as? [String], !embedded.isEmpty { // embeddedItems remains NSSet
        item[Keys.itemEmbeddedIDs] = embedded
    }

    // Logic for specific item types to determine paths
    let agentTypeFlag = TypeFlag.agent.rawValue
    let daemonTypeFlag = TypeFlag.daemon.rawValue
    let loginItemTypeFlag = TypeFlag.loginItem.rawValue
    let appTypeFlag = TypeFlag.app.rawValue

    // Agent or Daemon (type & 0x8 || type & 0x10)
    if (record.type & agentTypeFlag != 0) || (record.type & daemonTypeFlag != 0) {
        if let urlPath = record.url?.path, !urlPath.isEmpty {
            // Plist path is in url for agents/daemons
            item[Keys.itemPlistPath] = urlPath
        }
        // Exe path is assumed to be already set in record.executablePath
    }
    // Login Item (type & 0x4)
    else if record.type & loginItemTypeFlag != 0 {
        if let parentRecord = findParent(record, items: allItemsForUser),
           let parentURLPath = parentRecord.url?.path,
           let recordURLPath = record.url?.path // Login item URL path is relative within parent
        {
            // Construct potential bundle path relative to parent
            let potentialBundlePath = parentURLPath + recordURLPath
            if let bundle = Bundle(path: potentialBundlePath) {
                if let exePath = bundle.executablePath, !exePath.isEmpty {
                    item[Keys.itemExePath] = exePath // Override original exe path
                }
            } else {
                print("Warning: Could not load bundle for Login Item at constructed path: \(potentialBundlePath)")
            }
        } else {
            print("Warning: Could not find parent or parent/item URL for Login Item: \(record.identifier ?? "N/A")")
        }
    }
    // App (type & 0x2)
    else if record.type & appTypeFlag != 0 {
        if let appBundlePath = record.url?.path, !appBundlePath.isEmpty {
            if let bundle = Bundle(path: appBundlePath) {
                if let exePath = bundle.executablePath, !exePath.isEmpty {
                    item[Keys.itemExePath] = exePath // Override original exe path
                }
            } else {
                print("Warning: Could not load bundle for App Item at path: \(appBundlePath)")
            }
        } else {
            print("Warning: Missing URL path for App Item: \(record.identifier ?? "N/A")")
        }
    }

    return item
}

private func findParent(_ record: ItemRecord, items: [ItemRecord]) -> ItemRecord? {
    guard let containerID = record.container, !containerID.isEmpty else {
        return nil
    }
    return items.first { $0.identifier == containerID }
}
