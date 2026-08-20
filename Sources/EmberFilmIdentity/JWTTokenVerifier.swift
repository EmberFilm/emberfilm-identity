//
//  JWTTokenVerifier.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import JWTKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Verifies EmberFilm access tokens.
///
/// This type cannot mint tokens. Signing lives in `EmberFilmIdentitySigning`, which only
/// the issuing service depends on.
public struct JWTTokenVerifier: Sendable {
    private let keyCollection: JWTKeyCollection

    /// Verifies against the caller-supplied key set, which also selects the algorithm.
    public init(keyCollection: JWTKeyCollection) {
        self.keyCollection = keyCollection
    }

    public func verify(_ token: String) async throws -> JWTUserPayload {
        return try await keyCollection.verify(token)
    }
}
