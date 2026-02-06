// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Clack",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Clack",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
