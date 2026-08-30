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

    /// The identity this signer would put in a token for `subject`, valid for `expiration` from
    /// now.
    ///
    /// The caller states who the token is for, what they may do, and how long it lasts. `role` is
    /// theirs to state because only they have looked the subject up; this signer knows how to
    /// attest a claim, not what is true of a user. The issuer and the issued-at are the signer's,
    /// not theirs: `iss` is a property of the service doing the signing rather than of any one
    /// token, so stating it at each call site would be the same value repeated at every one of
    /// them and wrong at whichever one drifted.
    ///
    /// This is the only way to obtain an ``Identity``, which is what keeps that true — the claims
    /// cannot be assembled anywhere else and handed to ``signIdentity(_:)``.
    ///
    /// It is returned rather than signed in one step because a caller usually has to report when
    /// the token expires, and deriving that a second time would leave the token and what the
    /// caller says about it as two readings of the clock that can disagree.
    public func makeIdentity(
        subject: String,
        role: UserRole,
        expiration: TimeInterval
    ) -> Identity {
        let now = Date.now

        return Identity(
            subject: subject,
            role: role,
            issuer: IssuerClaim(value: configuration.issuer),
            issuedAt: IssuedAtClaim(value: now),
            expiration: ExpirationClaim(value: now.addingTimeInterval(expiration))
        )
    }

    public func signIdentity(_ identity: Identity) async throws -> String {
        try await keys.sign(identity)
    }
}
