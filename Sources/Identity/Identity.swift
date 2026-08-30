//
//  Identity.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import JWTKit

public struct Identity: JWTPayload {
    public let subject: String
    public let role: Role
    public let issuer: IssuerClaim
    public let issuedAt: IssuedAtClaim
    public let expiration: ExpirationClaim

    init(
        subject: String,
        role: Role,
        issuer: IssuerClaim,
        issuedAt: IssuedAtClaim,
        expiration: ExpirationClaim
    ) {
        self.subject = subject
        self.role = role
        self.issuer = issuer
        self.issuedAt = issuedAt
        self.expiration = expiration
    }

    public func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }

    private enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case role
        case issuer = "iss"
        case issuedAt = "iat"
        case expiration = "exp"
    }
}
