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
        ),
        .library(
            name: "ServiceIdentity",
            targets: ["ServiceIdentity"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.3.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.26.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.2.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.32.0"),
        .package(url: "https://github.com/EmberFilm/emberfilm-protos.git", from: "0.8.0"),
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
        ),
        // The one target that knows the authentication contract. A process that acts as itself
        // links it; a service that only verifies tokens never pulls the contract in.
        .target(
            name: "ServiceIdentity",
            dependencies: [
                "Identity",
                "IdentityGRPC",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "AuthenticationProtos", package: "emberfilm-protos"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
