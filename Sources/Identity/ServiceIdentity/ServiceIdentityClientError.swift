//
//  ServiceIdentityClientError.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

/// Why the issuer did not hand over a token, classified so a session can decide what to do
/// with the token it already holds.
///
/// `invalidCredentials` is the one code that means the process's own standing is gone: the
/// credential was revoked or never existed, and no retry will change that. `unavailable` is the
/// issuer being unreachable, which says nothing about the credential — the current token stays
/// good until it actually expires.
public struct ServiceIdentityClientError: Error {
    public let code: Code
    public let underlyingError: (any Error)?

    public enum Code: Sendable {
        case invalidCredentials
        case unavailable
        case unknown
    }

    public init(_ code: Code, underlyingError: (any Error)? = nil) {
        self.code = code
        self.underlyingError = underlyingError
    }
}
