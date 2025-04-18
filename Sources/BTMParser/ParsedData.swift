//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// Represents a processed background task management item.
public struct ParsedItem: Encodable {
    // Use CodingKeys to map struct properties to the desired JSON keys (from Keys enum)
    private enum CodingKeys: String, CodingKey {
        case identifier = "itemID"
        case uuid = "itemUUID"
        case name = "itemName"
        case developerName = "itemDevName"
        case teamIdentifier = "itemTeamID"
        case type = "itemType"
        case typeDetails = "itemTypeDetails"
        case disposition = "itemDisposition"
        case dispositionDetails = "itemDispositionDetails"
        case url = "itemURL"
        case executablePath = "itemExePath"
        case bundleIdentifier = "itemBundleID"
        // parentIdentifier is derived, not directly encoded/decoded from a primary key
        case containerIdentifier = "itemContainer" // Maps to 'containerIdentifier' property
        case associatedBundleIdentifiers = "associatedBundleIDs" // Corresponds to Keys.itemAssociatedIDs
        case generation = "itemGeneration"
    }

    public let identifier: String
    public let uuid: String
    public let name: String
    public let developerName: String? // Optional based on original data
    public let teamIdentifier: String?
    public let type: Int64
    public let typeDetails: String
    public let disposition: Int64
    public let dispositionDetails: String
    public let url: URL?
    public let executablePath: String?
    public let bundleIdentifier: String?
    public let parentIdentifier: String? // Logical parent (based on container lookup)
    public let containerIdentifier: String? // Raw container ID from ItemRecord
    public let associatedBundleIdentifiers: [String]?
    public let generation: Int64?
}

/// Represents the entire parsed content of a BTM file.
public struct ParsedData: Encodable {
    public let path: String
    public let itemsByUserID: [String: [ParsedItem]]
    // Keep MDM payloads as [String: Any] for now, as their structure is less defined
    public let mdmPayloadsByIdentifier: [String: Any]?

    // Add CodingKeys for manual encoding
    private enum CodingKeys: String, CodingKey {
        case path
        case itemsByUserID
        // We omit mdmPayloadsByIdentifier here as we won't encode it automatically
    }

    init(path: String, itemsByUserID: [String: [ParsedItem]], mdmPayloadsByIdentifier: [String: Any]?) {
        self.path = path
        self.itemsByUserID = itemsByUserID
        self.mdmPayloadsByIdentifier = mdmPayloadsByIdentifier
    }

    // Manual implementation of encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.path, forKey: .path)
        try container.encode(self.itemsByUserID, forKey: .itemsByUserID)
    }
}
