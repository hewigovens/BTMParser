// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "BTMParser",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "BTMParser",
            targets: ["BTMParser"]
        ),
        .executable(
            name: "btm-dumper",
            targets: ["btm-dumper"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BTMParser",
            dependencies: [],
            path: "Sources/BTMParser"
        ),
        .executableTarget(
            name: "btm-dumper",
            dependencies: ["BTMParser"],
            path: "Sources/btm-dumper"
        ),
        .testTarget(
            name: "BTMParserTests",
            dependencies: ["BTMParser"],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
