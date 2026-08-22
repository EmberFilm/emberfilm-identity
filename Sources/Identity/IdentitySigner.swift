//
//  IdentitySigner.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/21/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import JWTKit

/// Mints access tokens for the one service that holds the private key.
///
/// Every other service is configured with the matching public key and an ``IdentityVerifier``,
/// which reads a token but cannot produce one.
public struct IdentitySigner: Sendable {
    public struct Configuration: Sendable {
        public let issuer: String
        public let privateKey: EdDSA.PrivateKey
        
        public init(issuer: String, privateKey: EdDSA.PrivateKey) {
            self.issuer = issuer
            self.privateKey = privateKey
        }
    }

    private let keys: JWTKeyCollection
    private let configuration: Configuration

    public init(configuration: Configuration) async throws {
        self.configuration = configuration

        let keys = JWTKeyCollection()
        await keys.add(eddsa: configuration.privateKey)
        self.keys = keys
    }

    /// Signs a token naming `subject` as the caller, valid for `expiration` from now.
    ///
    /// The caller states who the token is for and how long it lasts. The issuer and the issued-at
    /// are the signer's, not theirs: `iss` is a property of the service doing the signing rather
    /// than of any one token, so stating it at each call site would be the same value repeated at
    /// every one of them and wrong at whichever one drifted.
    public func sign(
        subject: String,
        expiration: TimeInterval
    ) async throws -> String {
        let now = Date.now

        let identity = Identity(
            subject: subject,
            issuer: IssuerClaim(value: configuration.issuer),
            issuedAt: IssuedAtClaim(value: now),
            expiration: ExpirationClaim(value: now.addingTimeInterval(expiration))
        )

        return try await keys.sign(identity)
    }
}
