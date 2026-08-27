//
//  ServiceIdentityToken.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// What a process is handed for its credentials: an access token and when it stops working.
///
/// The expiry is carried alongside the token rather than read out of it, so a session can plan
/// a refresh without a verifier or the public key — the issuer already knows and says.
public struct ServiceIdentityToken: Equatable, Sendable {
    public let accessToken: String
    public let expirationDate: Date

    public init(accessToken: String, expirationDate: Date) {
        self.accessToken = accessToken
        self.expirationDate = expirationDate
    }

    public func isExpiring(within leeway: TimeInterval) -> Bool {
        expirationDate.timeIntervalSinceNow <= leeway
    }
}
