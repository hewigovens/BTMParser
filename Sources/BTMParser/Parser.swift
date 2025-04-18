//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// Parses the BTM (Background Task Management) database using pure Swift.
/// - Parameter btmPath: An optional URL pointing to a specific BTM database file. If nil, the default system path is used.
/// - Returns: A dictionary representing the parsed BTM data, or nil on failure.
/// - Throws: `BTMParserError` if the file is not found or parsing fails.
public enum BTMParser {
    public static func parse(path btmPath: URL) throws -> ParsedData {
        let filePath = btmPath.path
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw BTMParserError.fileNotFound(path: filePath)
        }

        do {
            // 1. Read Data
            let data = try Data(contentsOf: btmPath)

            // 2. Unarchive Data using helper
            let storage = try Self._unarchiveBTMData(data: data)

            // Safely cast and process itemsByUserID
            guard let rawItemsDict = storage.itemsByUserIdentifier as? [String: [ItemRecord]] else {
                // Handle case where casting fails or key is missing, maybe return empty?
                print("Warning: 'itemsByUserID' key missing or has unexpected type.")
                return ParsedData(path: filePath, itemsByUserID: [:], mdmPayloadsByIdentifier: storage.mdmPayloadsByIdentifier as? [String: Any])
            }

            let processedItemsByUserID: [String: [ParsedItem]] = rawItemsDict.mapValues { records in
                records.compactMap { Self.processRecord($0) }
            }

            // Process MDM payloads (currently just casting)
            let mdmPayloads = storage.mdmPayloadsByIdentifier as? [String: Any]

            // Second pass to resolve executable paths for specific item types (Login Items, Apps)
            let resolvedItemsByUserID = processedItemsByUserID.mapValues { userItems in
                Self.resolveExecutablePaths(for: userItems)
            }

            return ParsedData(
                path: filePath,
                itemsByUserID: resolvedItemsByUserID,
                mdmPayloadsByIdentifier: mdmPayloads
            )
        } catch let error as BTMParserError {
            throw error
        } catch {
            throw BTMParserError.unarchiveFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Private Static Helpers

    // Private helper to handle NSKeyedUnarchiver logic
    private static func _unarchiveBTMData(data: Data) throws -> Storage {
        do {
            // Define allowed classes FIRST
            let allowedClasses: [AnyClass] = [
                Storage.self,
                ItemRecord.self,
                NSDictionary.self,
                NSArray.self,
                NSString.self,
                NSNumber.self,
                NSUUID.self,
                NSURL.self,
                NSDate.self,
            ]
            // Initialize unarchiver requiring secure coding
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
            // DO NOT set allowedClasses here

            // Attempt to decode the 'store' object, PASSING allowedClasses
            guard let storage = unarchiver.decodeObject(of: allowedClasses, forKey: "store") as? Storage else {
                // Fallback: Try decoding 'storeData' if 'store' fails
                if let storeData = unarchiver.decodeObject(forKey: "storeData") as? Data,
                   let nestedUnarchiver = try? NSKeyedUnarchiver(forReadingFrom: storeData)
                {
                    nestedUnarchiver.requiresSecureCoding = true
                    // DO NOT set allowedClasses here either
                    // Decode nested object, PASSING allowedClasses
                    if let nestedStorage = nestedUnarchiver.decodeObject(of: allowedClasses, forKey: NSKeyedArchiveRootObjectKey) as? Storage {
                        print("Decoded Storage object using 'storeData' key.")
                        nestedUnarchiver.finishDecoding()
                        return nestedStorage
                    } else {
                        nestedUnarchiver.finishDecoding()
                    }
                }
                // If both attempts fail
                throw BTMParserError.unarchiveFailed(reason: "Could not decode Storage object using 'store' or 'storeData' keys.")
            }
            print("Decoded Storage object using 'store' key.")
            unarchiver.finishDecoding()
            return storage
        } catch let error as BTMParserError {
            throw error // Re-throw our specific errors
        } catch {
            // Wrap other unarchiving errors
            throw BTMParserError.unarchiveFailed(reason: "NSKeyedUnarchiver error: \(error.localizedDescription)")
        }
    }

    // Private helper to convert ItemRecord to ParsedItem
    private static func processRecord(_ record: ItemRecord) -> ParsedItem? {
        // Ensure required fields are present
        guard let identifier = record.identifier, !identifier.isEmpty,
              let uuid = record.uuid, !uuid.isEmpty, // Assuming record.uuid is String?
              let name = record.name, !name.isEmpty
        else {
            // Log potentially incomplete record? For now, just skip.
            print("Skipping record due to missing identifier, uuid, or name: \(record)")
            return nil
        }

        return ParsedItem(
            identifier: identifier,
            uuid: uuid, // Pass the unwrapped String directly
            name: name,
            developerName: record.developerName,
            teamIdentifier: record.teamIdentifier,
            type: record.type, // Keep raw Int64 type
            typeDetails: TypeFlag.typeDetails(record), // Generate details string
            disposition: record.disposition, // Keep raw Int64 disposition
            dispositionDetails: DispositionFlag.dispositionDetails(record), // Generate details string
            url: record.url,
            executablePath: record.executablePath, // Initial path, might be refined later
            bundleIdentifier: record.bundleIdentifier,
            parentIdentifier: record.container, // Corrected: Use 'container' from ItemRecord
            containerIdentifier: record.container, // Renamed key in ParsedItem struct
            associatedBundleIdentifiers: record.associatedBundleIdentifiers as? [String], // Cast needed
            generation: record.generation // Assign Int64 directly to Int64?
        )
    }

    // Helper to find a parent ParsedItem based on containerIdentifier
    private static func findParent(for item: ParsedItem, in allItems: [ParsedItem]) -> ParsedItem? {
        guard let containerID = item.containerIdentifier, !containerID.isEmpty else {
            return nil // Item has no container ID
        }
        // The containerID in ItemRecord corresponds to the parent's identifier
        return allItems.first { $0.identifier == containerID }
    }

    // Second pass to resolve executable paths for specific item types (Login Items, Apps)
    private static func resolveExecutablePaths(for userItems: [ParsedItem]) -> [ParsedItem] {
        return userItems.map { item in
            var updatedItem = item // Create a mutable copy

            // Login Item (type & 0x4)
            if TypeFlag(rawValue: item.type).contains(.loginItem) {
                if let parent = Self.findParent(for: item, in: userItems),
                   let parentURLPath = parent.url?.path,
                   let itemURLPath = item.url?.path // Login item URL path is relative within parent
                {
                    // Construct potential bundle path relative to parent
                    let potentialBundlePath = parentURLPath + itemURLPath
                    if let bundle = Bundle(path: potentialBundlePath) {
                        if let exePath = bundle.executablePath, !exePath.isEmpty {
                            updatedItem = ParsedItem(
                                identifier: item.identifier, uuid: item.uuid, name: item.name,
                                developerName: item.developerName, teamIdentifier: item.teamIdentifier,
                                type: item.type, typeDetails: item.typeDetails,
                                disposition: item.disposition, dispositionDetails: item.dispositionDetails,
                                url: item.url, executablePath: exePath, // Updated path
                                bundleIdentifier: item.bundleIdentifier, parentIdentifier: item.parentIdentifier,
                                containerIdentifier: item.containerIdentifier,
                                associatedBundleIdentifiers: item.associatedBundleIdentifiers,
                                generation: item.generation
                            )
                        } else {
                            print("Warning: Found bundle for Login Item but couldn't get executablePath: \(potentialBundlePath)")
                        }
                    } else {
                        print("Warning: Could not load bundle for Login Item at constructed path: \(potentialBundlePath)")
                    }
                } else {
                    print("Warning: Could not find parent or parent/item URL for Login Item: \(item.identifier)")
                }
            }
            // App (type & 0x2)
            else if TypeFlag(rawValue: item.type).contains(.app) {
                if let appBundlePath = item.url?.path, !appBundlePath.isEmpty {
                    if let bundle = Bundle(path: appBundlePath) {
                        if let exePath = bundle.executablePath, !exePath.isEmpty {
                            updatedItem = ParsedItem(
                                identifier: item.identifier, uuid: item.uuid, name: item.name,
                                developerName: item.developerName, teamIdentifier: item.teamIdentifier,
                                type: item.type, typeDetails: item.typeDetails,
                                disposition: item.disposition, dispositionDetails: item.dispositionDetails,
                                url: item.url, executablePath: exePath, // Updated path
                                bundleIdentifier: item.bundleIdentifier, parentIdentifier: item.parentIdentifier,
                                containerIdentifier: item.containerIdentifier,
                                associatedBundleIdentifiers: item.associatedBundleIdentifiers,
                                generation: item.generation
                            )
                        } else {
                            print("Warning: Found bundle for App Item but couldn't get executablePath: \(appBundlePath)")
                        }
                    } else {
                        print("Warning: Could not load bundle for App Item at path: \(appBundlePath)")
                    }
                } else {
                    print("Warning: Missing URL path for App Item: \(item.identifier)")
                }
            }

            return updatedItem // Return the original or updated item
        }
    }
}
