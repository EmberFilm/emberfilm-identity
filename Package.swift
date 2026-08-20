// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "emberfilm-identity",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "EmberFilmIdentity",
            targets: ["EmberFilmIdentity"]
        ),
        .library(
            name: "EmberFilmIdentityGRPC",
            targets: ["EmberFilmIdentityGRPC"]
        ),
        .library(
            name: "EmberFilmIdentityHTTP",
            targets: ["EmberFilmIdentityHTTP"]
        ),
        .library(
            name: "EmberFilmIdentitySigning",
            targets: ["EmberFilmIdentitySigning"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.26.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.2.0")
    ],
    targets: [
        .target(
            name: "EmberFilmIdentity",
            dependencies: [
                .product(name: "JWTKit", package: "jwt-kit")
            ]
        ),
        .target(
            name: "EmberFilmIdentityGRPC",
            dependencies: [
                "EmberFilmIdentity",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
            ]
        ),
        .target(
            name: "EmberFilmIdentityHTTP",
            dependencies: [
                "EmberFilmIdentity",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
            ]
        ),
        .target(
            name: "EmberFilmIdentitySigning",
            dependencies: [
                "EmberFilmIdentity",
                .product(name: "JWTKit", package: "jwt-kit"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
