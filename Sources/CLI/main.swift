//  Copyright 2023 Objective-See
//  Copyright 2025 Tao Xu
//  SPDX-License-Identifier: GPL-3.0-or-later

import BTMParser
import Foundation

func printUsage() {
    let prog = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "btm-dumper"
    let usage = """
    usage: \(prog) [-h] [-f FILE] [-o OUT] [-v]

    Parses BackgroundItems-v*.btm file (macOS 13+).

    required arguments:
      -f, --file FILE       Path to BackgroundItems-v*.btm

    optional arguments:
      -h, --help            Show this help message and exit
      -o, --out OUT         Path to output filename
      -v, --version         Show version and exit
    """
    print(usage)
}

func main() {
    var fileURL: URL?
    var outputPath: String?

    let args = Array(CommandLine.arguments.dropFirst())

    if args.isEmpty {
        printUsage()
        exit(0)
    }

    var i = 0
    while i < args.count {
        let arg = args[i]
        switch arg {
        case "-f", "--file":
            i += 1
            guard i < args.count else { fputs("Missing value for \(arg)\n", stderr); exit(1) }
            fileURL = URL(fileURLWithPath: args[i])
        case "-o", "--out":
            i += 1
            guard i < args.count else { fputs("Missing value for \(arg)\n", stderr); exit(1) }
            outputPath = args[i]
        case "-h", "--help":
            printUsage()
            exit(0)
        case "-v", "--version":
            print("v\(BTMParser.version)")
            exit(0)
        default:
            fputs("Unknown argument: \(arg)\n", stderr)
            printUsage()
            exit(1)
        }
        i += 1
    }

    guard let fileURL = fileURL else {
        fputs("Error: No input file specified.\n", stderr)
        exit(1)
    }

    // Parse the BTM database
    do {
        let parsedData: ParsedData = try BTMParser.parse(path: fileURL)

        // Use JSONEncoder for Encodable types
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        // Encode the ParsedData struct directly
        let jsonData = try encoder.encode(parsedData)

        // Convert JSON data to a string and print
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            fputs("Error: Failed to convert JSON data to string.\n", stderr)
            exit(1)
        }

        if let outputPath = outputPath {
            try jsonString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Parsed data written to \(outputPath)")
        } else {
            print(jsonString)
        }
        exit(0)

    } catch let error as BTMParserError {
        switch error {
        case .fileNotFound(let path):
            fputs("Error: BTM file not found at path: \(path)\n", stderr)
        case .parsingFailed(let reason):
            fputs("Error: Failed to parse BTM file. Reason: \(reason)\n", stderr)
        case .unarchiveFailed(let reason):
            fputs("Error: Failed to unarchive BTM data. Reason: \(reason)\n", stderr)
        }
        exit(1)
    } catch {
        fputs("An unexpected error occurred: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

main()
