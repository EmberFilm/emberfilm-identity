//
//  JWTTokenSigner.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import EmberFilmIdentity
import JWTKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Mints EmberFilm access tokens.
///
/// Only the issuing service should depend on this target. Every other service verifies with
/// `EmberFilmIdentity` and has no way to produce a token.
public struct JWTTokenSigner: Sendable {
    private let keys: JWTKeyCollection
    private let issuer: String

    /// Signs with the caller-supplied key set, which also selects the algorithm.
    public init(
        keys: JWTKeyCollection,
        issuer: String
    ) {
        self.keys = keys
        self.issuer = issuer
    }

    /// Signs a token carrying the given identity, valid until `expirationDate`.
    ///
    /// How long a token lives is the issuing service's policy, not this type's, so it is supplied
    /// per call rather than fixed when the signer is built.
    public func sign(userId: UUID, email: String, expirationDate: Date) async throws -> String {
        let claims = JWTUserPayload(
            userId: userId,
            issuer: IssuerClaim(value: issuer),
            issuedAt: IssuedAtClaim(value: .now),
            expiration: ExpirationClaim(value: expirationDate),
            email: email
        )
        return try await keys.sign(claims)
    }
}
