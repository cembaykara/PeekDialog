// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PeekDialog",
	platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(
            name: "PeekDialog",
            targets: ["PeekDialog"]),
    ],
    targets: [
		.target(
			name: "PeekDialog",
			path: "PeekDialog"),
    ]
)
