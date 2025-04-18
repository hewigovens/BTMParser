//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

public enum BTMParserError: Error, Equatable {
    case fileNotFound(path: String)
    case parsingFailed(reason: String)
    case unarchiveFailed(reason: String)
}

extension BTMParserError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .parsingFailed(let reason):
            return "Parsing failed: \(reason)"
        case .unarchiveFailed(let reason):
            return "Unarchiving failed: \(reason)"
        }
    }
}
