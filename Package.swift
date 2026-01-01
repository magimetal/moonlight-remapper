// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoonlightRemapper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MoonlightRemapper", targets: ["MoonlightRemapper"])
    ],
    targets: [
        .executableTarget(
            name: "MoonlightRemapper",
            path: "MoonlightRemapper"
        )
    ]
)
