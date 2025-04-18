//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

struct DispositionFlag: OptionSet {
    let rawValue: Int64

    static let enabled = DispositionFlag(rawValue: 1 << 0) // 0x1
    static let allowed = DispositionFlag(rawValue: 1 << 1) // 0x2
    static let hidden = DispositionFlag(rawValue: 1 << 2) // 0x4
    static let notified = DispositionFlag(rawValue: 1 << 3) // 0x8

    // Function to get disposition details string
    static func dispositionDetails(_ record: ItemRecord) -> String {
        let flags = DispositionFlag(rawValue: record.disposition)
        var details: [String] = []

        // Enabled / Disabled
        if flags.contains(.enabled) {
            details.append("enabled")
        } else {
            details.append("disabled")
        }

        // Allowed / Disallowed
        if flags.contains(.allowed) {
            details.append("allowed")
        } else {
            details.append("disallowed")
        }

        // Hidden / Visible
        if flags.contains(.hidden) {
            details.append("hidden")
        } else {
            details.append("visible")
        }

        // Notified / Not Notified
        if flags.contains(.notified) {
            details.append("notified")
        } else {
            details.append("not notified")
        }

        // Join details with space
        return details.joined(separator: " ")
    }
}

struct TypeFlag: OptionSet {
    let rawValue: Int64

    // Note: Values are not contiguous powers of 2, define them directly.
    static let app = TypeFlag(rawValue: 0x2)
    static let loginItem = TypeFlag(rawValue: 0x4)
    static let agent = TypeFlag(rawValue: 0x8)
    static let daemon = TypeFlag(rawValue: 0x10)
    static let developer = TypeFlag(rawValue: 0x20)

    static let legacy = TypeFlag(rawValue: 0x10000)
    static let curated = TypeFlag(rawValue: 0x80000)

    // Function to get type details string
    static func typeDetails(_ record: ItemRecord) -> String {
        let flags = TypeFlag(rawValue: record.type)
        var details = ""

        // Check flags (order might matter for readability/original logic)
        if flags.contains(.curated) {
            details += "curated "
        }
        if flags.contains(.legacy) {
            details += "legacy "
        }
        if flags.contains(.developer) {
            details += "developer "
        }
        if flags.contains(.daemon) {
            details += "daemon "
        }
        if flags.contains(.agent) {
            details += "agent "
        }
        if flags.contains(.loginItem) {
            details += "login item "
        }
        if flags.contains(.app) {
            details += "app "
        }

        // Remove trailing space if present
        return details.trimmingCharacters(in: .whitespaces)
    }
}
