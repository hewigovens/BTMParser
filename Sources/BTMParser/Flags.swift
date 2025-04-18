//  Copyright © 2023 Objective-See
//  Copyright © 2025 Tao Xu
//  SPDX‑License‑Identifier: GPL-3.0-or-later

import Foundation

enum DispositionFlag: Int64 {
    case enabled = 0x1
    case allowed = 0x2
    case hidden = 0x4
    case notified = 0x8

    // Function to get disposition details string
    static func dispositionDetails(_ record: ItemRecord) -> String {
        var details: [String] = []

        // Enabled / Disabled
        if (record.disposition & DispositionFlag.enabled.rawValue) != 0 {
            details.append("enabled")
        } else {
            details.append("disabled")
        }

        // Allowed / Disallowed
        if (record.disposition & DispositionFlag.allowed.rawValue) != 0 {
            details.append("allowed")
        } else {
            details.append("disallowed")
        }

        // Hidden / Visible
        if (record.disposition & DispositionFlag.hidden.rawValue) != 0 {
            details.append("hidden")
        } else {
            details.append("visible")
        }

        // Notified / Not Notified
        if (record.disposition & DispositionFlag.notified.rawValue) != 0 {
            details.append("notified")
        } else {
            details.append("not notified")
        }

        // Join details with space
        return details.joined(separator: " ")
    }
}

enum TypeFlag: Int64 {
    case curated = 0x80000
    case legacy = 0x10000
    case developer = 0x20
    case daemon = 0x10
    case agent = 0x8
    case loginItem = 0x4
    case app = 0x2

    // Function to get type details string
    static func typeDetails(_ record: ItemRecord) -> String {
        var details: String = ""

        // Check flags
        if (record.type & TypeFlag.curated.rawValue) != 0 {
            details += "curated "
        }
        if (record.type & TypeFlag.legacy.rawValue) != 0 {
            details += "legacy "
        }
        if (record.type & TypeFlag.developer.rawValue) != 0 {
            details += "developer "
        }
        if (record.type & TypeFlag.daemon.rawValue) != 0 {
            details += "daemon "
        }
        if (record.type & TypeFlag.agent.rawValue) != 0 {
            details += "agent "
        }
        if (record.type & TypeFlag.loginItem.rawValue) != 0 {
            details += "login item "
        }
        if (record.type & TypeFlag.app.rawValue) != 0 {
            details += "app "
        }

        // Remove trailing space if present
        return details.trimmingCharacters(in: .whitespaces)
    }
}
