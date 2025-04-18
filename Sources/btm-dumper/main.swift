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
    let btmData = try BTMParser.parse(path: inputFileURL)

    // Convert the dictionary to pretty-printed JSON data
    let jsonData = try JSONSerialization.data(
        withJSONObject: btmData,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    )

    // Convert JSON data to a string
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
    case .parsingFailed(let reason):
        fputs("Error: Failed to parse BTM file. Reason: \(reason)\n", stderr)
    }
    exit(1)
} catch {
    fputs("An unexpected error occurred: \(error.localizedDescription)\n", stderr)
    exit(1)
}
