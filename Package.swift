// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "itime",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "itime",
            path: "itime",
            exclude: ["Resources"],
            sources: [
                "App",
                "Models",
                "Engine",
                "Services",
                "UI",
                "Utilities",
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "itimeTests",
            dependencies: ["itime"],
            path: "itimeTests"
        ),
    ]
)
