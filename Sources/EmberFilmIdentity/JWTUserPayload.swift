//
//  JWTUserPayload.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import JWTKit

/// The claim set every EmberFilm access token carries.
///
/// This is the wire contract between the service that mints tokens and every service
/// that verifies them. Add claims with new keys; never repurpose an existing key.
public struct JWTUserPayload: JWTPayload, Sendable {
    public let userId: UUID
    public let issuer: IssuerClaim
    public let issuedAt: IssuedAtClaim
    public let expiration: ExpirationClaim
    public let email: String

    public init(
        userId: UUID,
        issuer: IssuerClaim,
        issuedAt: IssuedAtClaim,
        expiration: ExpirationClaim,
        email: String
    ) {
        self.userId = userId
        self.issuer = issuer
        self.issuedAt = issuedAt
        self.expiration = expiration
        self.email = email
    }

    private enum CodingKeys: String, CodingKey {
        case userId = "sub"
        case issuer = "iss"
        case issuedAt = "iat"
        case expiration = "exp"
        case email
    }

    public func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
