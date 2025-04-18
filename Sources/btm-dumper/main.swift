//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import BTMParser
import Foundation

// Determine the input path (if provided)
var inputFileURL: URL
if CommandLine.arguments.count > 1 {
    let pathString = CommandLine.arguments[1]
    inputFileURL = URL(fileURLWithPath: pathString)
} else {
    print("Usage: swift run btm-dumper file/path/to/BackgroundItems-vX.btm")
    exit(1)
}

// Parse the BTM database
do {
    let parsedData: ParsedData = try BTMParser.parse(path: inputFileURL)

    // Use JSONEncoder for Encodable types
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

    // Encode the ParsedData struct directly
    let jsonData = try encoder.encode(parsedData)

    // Convert JSON data to a string and print
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
        exit(0) // Success
    } else {
        fputs("Error: Failed to convert JSON data to string.\n", stderr)
        exit(1)
    }

} catch let error as BTMParserError {
    // Handle specific BTMParser errors
    switch error {
    case .fileNotFound(let path):
        fputs("Error: BTM file not found at path: \(path)\n", stderr)
    case .parsingFailed(let reason): // Keep this case for now, though unarchiveFailed might be more common
        fputs("Error: Failed to parse BTM file. Reason: \(reason)\n", stderr)
    case .unarchiveFailed(let reason): // Added case for specific unarchiving errors
        fputs("Error: Failed to unarchive BTM data. Reason: \(reason)\n", stderr)
    }
    exit(1)
} catch {
    fputs("An unexpected error occurred: \(error.localizedDescription)\n", stderr)
    exit(1)
}
