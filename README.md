# BTMParser
[![Swift](https://github.com/hewigovens/BTMParser/actions/workflows/swift.yml/badge.svg)](https://github.com/hewigovens/BTMParser/actions/workflows/swift.yml)

An open-source Swift package and command-line tool (`btm-dumper`) to parse macOS Background Task Management (BTM) files (`BackgroundItems-v*.btm`).

## Requirements

- macOS 10.15 or later
- Xcode 16 or later

## Building and Running

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/hewigovens/BTMParser.git
    cd BTMParser
    ```

2.  **Build the command-line tool:**
    ```bash
    swift build --target btm-dumper
    ```

3.  **Run the tool:**
    -   **To parse a specific BTM file:**
        Provide the path as a command-line argument.
        ```bash
        swift run btm-dumper /path/to/your/BackgroundItems-vX.btm
        ```

> [!NOTE]  
> You need Full Disk Access to read the default path `/private/var/db/com.apple.backgroundtaskmanagement/`.

## JSON Output

The tool outputs the parsed data as a JSON object to standard output:

```json
{
  "itemsByUserID" : {
    "770103FF-8EB4-455C-865F-6E4EAE62F8D7" : [
      {
        "bundleIdentifier" : "com.1password.1password",
        "developerName" : "AgileBits Inc.",
        "disposition" : 2,
        "dispositionDetails" : "disabled allowed visible not notified",
        "executablePath" : "/Applications/1Password.app/Contents/MacOS/1Password",
        "generation" : 18,
        "identifier" : "2.com.1password.1password",
        "name" : "1Password",
        "teamIdentifier" : "2BUA8C4S2C",
        "type" : 2,
        "typeDetails" : "app",
        "url" : "file:///Applications/1Password.app/",
        "uuid" : "55A31ED3-ADDE-4ABA-8BDC-19E88A31F18C"
      }
    ]
  },
  "path" : "<BackgroundItems-vX.btm>"
}
```

## Using the Library

You can add `BTMParser` as a dependency to your own Swift package:

```swift
// In your Package.swift
dependencies: [
    .package(url: "https://github.com/hewigovens/BTMParser.git", branch: "main")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["BTMParser"]),
]

```

Then, import and use it:

```swift
import BTMParser

do {
    // Parse a specific file
    if let fileURL = URL(string: "/path/to/BackgroundItems-vX.btm") {
        let btmData = try BTMParser.parse(path: fileURL)
        print(btmData)
    } else {
        print("Invalid URL")
    }

} catch let error as BTMParserError {
    print("BTMParser Error: \(error)")
} catch {
    print("An unexpected error occurred: \(error)")
}
```

## License

`BTMParser` is inspired by [DumpBTM](https://github.com/objective-see/DumpBTM) and is released under the same [License](./LICENSE).
