//  Copyright © 2023 Objective-See
//  Copyright © 2025 Tao Xu
//  SPDX‑License‑Identifier: GPL-3.0-or-later

public enum Keys {
    // Top-level keys
    public static let path = "path"
    public static let error = "error"
    public static let version = "version"
    public static let mdmPayload = "mdmPayload"
    public static let itemsByUserID = "itemsByUserIdentifier"
    public static let mdmPayloadsByIdentifier = "mdmPayloadsByIdentifier"

    // Item keys
    public static let itemID = "identifier"
    public static let itemURL = "url"
    public static let itemUUID = "uuid"
    public static let itemName = "name"
    public static let itemType = "type"
    public static let itemTeamID = "teamIdentifier"
    public static let itemDevName = "developerName"
    public static let itemBundleID = "bundleIdentifier"
    public static let itemContainer = "container"
    public static let itemPlistPath = "plistPath"
    public static let itemGeneration = "generation"
    public static let itemExePath = "executablePath"
    public static let itemDisposition = "disposition"
    public static let itemTypeDetails = "typeDetails"
    public static let itemEmbeddedItems = "embeddedItems"
    public static let itemEmbeddedIDs = "embeddedItemIdentifiers"
    public static let itemAssociatedIDs = "associatedBundleIdentifiers"
    public static let itemDispositionDetails = "dispositionDetails"
}
