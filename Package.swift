// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "emberfilm-identity",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Identity",
            targets: ["Identity"]
        ),
        .library(
            name: "IdentityGRPC",
            targets: ["IdentityGRPC"]
        ),
        .library(
            name: "IdentityHTTP",
            targets: ["IdentityHTTP"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.26.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.2.0")
    ],
    targets: [
        .target(
            name: "Identity",
            dependencies: [
                .product(name: "JWTKit", package: "jwt-kit")
            ]
        ),
        .target(
            name: "IdentityGRPC",
            dependencies: [
                "Identity",
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
            ]
        ),
        .target(
            name: "IdentityHTTP",
            dependencies: [
                "Identity",
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
