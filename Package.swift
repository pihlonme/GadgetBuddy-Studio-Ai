// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GadgetBuddyStudioAI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "GadgetBuddyCore", targets: ["GadgetBuddyCore"]),
        .library(name: "GadgetBuddyUI", targets: ["GadgetBuddyUI"]),
        .executable(name: "GadgetBuddyDemo", targets: ["GadgetBuddyDemo"])
    ],
    targets: [
        .target(name: "GadgetBuddyCore"),
        .target(name: "GadgetBuddyUI", dependencies: ["GadgetBuddyCore"]),
        .executableTarget(name: "GadgetBuddyDemo", dependencies: ["GadgetBuddyUI"]),
        .testTarget(
            name: "GadgetBuddyCoreTests",
            dependencies: ["GadgetBuddyCore", "GadgetBuddyUI"],
            path: "Tests",
            resources: [.copy("Fixtures")]
        )
    ]
)
