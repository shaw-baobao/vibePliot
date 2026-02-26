// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibePilot",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "VibePilotCore", targets: ["VibePilotCore"]),
        .executable(name: "VibePilot", targets: ["VibePilot"])
    ],
    targets: [
        .target(
            name: "VibePilotCore",
            path: "Sources/VibePilotCore",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Vision"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .executableTarget(
            name: "VibePilot",
            dependencies: ["VibePilotCore"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "VibePilotCoreTests",
            dependencies: ["VibePilotCore"],
            path: "Tests/VibePilotCoreTests"
        )
    ]
)

