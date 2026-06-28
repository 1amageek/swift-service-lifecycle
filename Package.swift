// swift-tools-version:6.1
import Foundation
import PackageDescription

let manifestDirectoryURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

func localOrForkDependency(_ repository: String, localPath: String) -> Package.Dependency {
    let resolvedLocalPath = URL(fileURLWithPath: localPath, relativeTo: manifestDirectoryURL)
        .standardizedFileURL
        .path
    if FileManager.default.fileExists(atPath: resolvedLocalPath) {
        return .package(path: resolvedLocalPath)
    }

    return .package(url: "https://github.com/1amageek/\(repository).git", branch: "main")
}

let package = Package(
    name: "swift-service-lifecycle",
    products: [
        .library(
            name: "ServiceLifecycle",
            targets: ["ServiceLifecycle"]
        ),
        .library(
            name: "ServiceLifecycleTestKit",
            targets: ["ServiceLifecycleTestKit"]
        ),
        .library(
            name: "UnixSignals",
            targets: ["UnixSignals"]
        ),
    ],
    dependencies: [
        localOrForkDependency("swift-log", localPath: "../swift-log"),
        localOrForkDependency("swift-async-algorithms", localPath: "../swift-async-algorithms"),
    ],
    targets: [
        .target(
            name: "ServiceLifecycle",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                .product(
                    name: "AsyncAlgorithms",
                    package: "swift-async-algorithms"
                ),
                .target(name: "UnixSignals"),
                .target(name: "ConcurrencyHelpers"),
            ]
        ),
        .target(
            name: "ServiceLifecycleTestKit",
            dependencies: [
                .target(name: "ServiceLifecycle")
            ]
        ),
        .target(
            name: "UnixSignals",
            dependencies: [
                .target(name: "ConcurrencyHelpers")
            ]
        ),
        .target(
            name: "ConcurrencyHelpers"
        ),
        .testTarget(
            name: "ServiceLifecycleTests",
            dependencies: [
                .target(name: "ServiceLifecycle"),
                .target(name: "ServiceLifecycleTestKit"),
            ]
        ),
        .testTarget(
            name: "UnixSignalsTests",
            dependencies: [
                .target(name: "UnixSignals")
            ]
        ),
    ]
)

for target in package.targets {
    #if compiler(<6.2)
    // Needed since Sendable checking with isolated methods is not working correctly before 6.2
    if target.swiftSettings == nil {
        target.swiftSettings = []
    }
    target.swiftSettings?.append(.swiftLanguageMode(.v5))
    #endif
}
