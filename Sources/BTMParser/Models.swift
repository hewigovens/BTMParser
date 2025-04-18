//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

// MARK: - Data Model Classes (ObjC Private Classes)

@objc(Storage)
final class Storage: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true

    var itemsByUserIdentifier: NSDictionary?
    var mdmPayloadsByIdentifier: NSDictionary?

    init?(coder decoder: NSCoder) {
        super.init()
        let allowedClassesForItems: [AnyClass] = [NSDictionary.self, NSArray.self, ItemRecord.self, NSString.self, NSNumber.self, NSURL.self, NSSet.self]
        self.itemsByUserIdentifier = decoder
            .decodeObject(
                of: allowedClassesForItems,
                forKey: Keys.itemsByUserID
            ) as? NSDictionary

        let allowedClassesForMDM: [AnyClass] = [NSDictionary.self, NSString.self, NSNumber.self]
        self.mdmPayloadsByIdentifier = decoder
            .decodeObject(
                of: allowedClassesForMDM,
                forKey: Keys.mdmPayloadsByIdentifier
            ) as? NSDictionary
    }

    func encode(with encoder: NSCoder) {
        // Encode properties
        encoder.encode(self.itemsByUserIdentifier, forKey: Keys.itemsByUserID)
        encoder.encode(self.mdmPayloadsByIdentifier, forKey: Keys.mdmPayloadsByIdentifier)
    }
}

@objc(ItemRecord)
final class ItemRecord: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true

    var uuid: String?
    var name: String?
    var developerName: String?
    var teamIdentifier: String?
    var identifier: String?
    var url: URL?
    var type: Int64 = 0
    var bundleIdentifier: String?
    var container: String? // Parent ID
    var executablePath: String?
    var generation: Int64 = 0
    var disposition: Int64 = 0
    var associatedBundleIdentifiers: NSArray? // Array of Strings
    var embeddedItems: NSSet? // Set of Strings (Identifiers)

    override init() {
        super.init()
    }

    // Required NSSecureCoding initializers
    init?(coder decoder: NSCoder) {
        // swiftformat:disable maxwidth
        super.init()
        // Decode UUID as NSUUID and convert to string
        self.uuid = (decoder.decodeObject(of: NSUUID.self, forKey: Keys.itemUUID) as NSUUID?)?.uuidString
        self.name = decoder.decodeObject(of: NSString.self, forKey: Keys.itemName) as String?
        self.developerName = decoder.decodeObject(of: NSString.self, forKey: Keys.itemDevName) as String?
        self.teamIdentifier = decoder.decodeObject(of: NSString.self, forKey: Keys.itemTeamID) as String?
        self.identifier = decoder.decodeObject(of: NSString.self, forKey: Keys.itemID) as String?
        self.url = decoder.decodeObject(of: NSURL.self, forKey: Keys.itemURL) as URL?
        self.type = decoder.decodeInt64(forKey: Keys.itemType)
        self.bundleIdentifier = decoder.decodeObject(of: NSString.self, forKey: Keys.itemBundleID) as String?
        self.container = decoder.decodeObject(of: NSString.self, forKey: Keys.itemContainer) as String?
        self.executablePath = decoder.decodeObject(of: NSString.self, forKey: Keys.itemExePath) as String?
        self.generation = decoder.decodeInt64(forKey: Keys.itemGeneration)
        self.disposition = decoder.decodeInt64(forKey: Keys.itemDisposition)
        // Decode associatedBundleIdentifiers as NSArray containing NSStrings
        self.associatedBundleIdentifiers = decoder.decodeObject(
            of: [NSArray.self, NSString.self],
            forKey: Keys.itemAssociatedIDs
        ) as? NSArray
        self.embeddedItems = decoder.decodeObject(
            of: [NSSet.self, NSString.self],
            forKey: Keys.itemEmbeddedItems
        ) as? NSSet
        // swiftformat:enable all
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(self.uuid, forKey: Keys.itemUUID)
        encoder.encode(self.name, forKey: Keys.itemName)
        encoder.encode(self.developerName, forKey: Keys.itemDevName)
        encoder.encode(self.teamIdentifier, forKey: Keys.itemTeamID)
        encoder.encode(self.identifier, forKey: Keys.itemID)
        encoder.encode(self.url, forKey: Keys.itemURL)
        encoder.encode(self.type, forKey: Keys.itemType)
        encoder.encode(self.bundleIdentifier, forKey: Keys.itemBundleID)
        encoder.encode(self.container, forKey: Keys.itemContainer)
        encoder.encode(self.executablePath, forKey: Keys.itemExePath)
        encoder.encode(self.generation, forKey: Keys.itemGeneration)
        encoder.encode(self.disposition, forKey: Keys.itemDisposition)
        encoder.encode(self.associatedBundleIdentifiers, forKey: Keys.itemAssociatedIDs)
        encoder.encode(self.embeddedItems, forKey: Keys.itemEmbeddedItems)
    }
}
