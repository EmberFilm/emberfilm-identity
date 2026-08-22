//
//  Identity.swift
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

public struct Identity: JWTPayload {
    public let subject: String
    public let issuer: IssuerClaim
    public let issuedAt: IssuedAtClaim
    public let expiration: ExpirationClaim

    public init(
        subject: String,
        issuer: IssuerClaim,
        issuedAt: IssuedAtClaim,
        expiration: ExpirationClaim
    ) {
        self.subject = subject
        self.issuer = issuer
        self.issuedAt = issuedAt
        self.expiration = expiration
    }
    
    public init(
        subject: String,
        issuer: IssuerClaim,
        expiration: TimeInterval
    ) {
        let now = Date.now
        self.init(
            subject: subject,
            issuer: issuer,
            issuedAt: IssuedAtClaim(value: now),
            expiration: ExpirationClaim(value: now.addingTimeInterval(expiration))
        )
    }

    public func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }

    private enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case issuer = "iss"
        case issuedAt = "iat"
        case expiration = "exp"
    }
}
