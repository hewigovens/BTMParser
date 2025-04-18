//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

public enum BTMParserError: Error, Equatable {
    case fileNotFound(path: String)
    case parsingFailed(reason: String)
}
