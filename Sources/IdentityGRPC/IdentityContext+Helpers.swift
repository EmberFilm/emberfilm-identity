//
//  IdentityContext+Helpers.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import GRPCCore
import Identity

/// The checks a gRPC handler makes before acting on a caller.
///
/// `IdentityServerInterceptor` identifies a caller without requiring one; requiring is the
/// handler's decision, made per RPC, and these are the forms it takes. Each distinguishes having
/// no caller from having the wrong one: a missing identity is `unauthenticated`, because
/// presenting a token could change the answer; a caller who is identified but not the kind the
/// RPC takes gets `permissionDenied`, where presenting a different token could not. Reporting both
/// the same way would tell a client to go and refresh a token that was never the problem, and it
/// will keep refreshing.
extension IdentityContext {
    /// The caller, whoever they are.
    @discardableResult
    public static func requireIdentity() throws -> Identity {
        guard let context = current else {
            throw RPCError(
                code: .unauthenticated,
                message: "Authentication is required."
            )
        }

        return context.identity
    }

    /// The caller as a person, with the user they are.
    ///
    /// The role is the test, not the shape of the subject: a process's subject is whatever name
    /// its credential was issued under, and nothing stops that name from being a UUID. A person's
    /// token whose subject is not a user id names nobody the RPC can act for.
    @discardableResult
    public static func requireUserIdentity() throws -> (identity: Identity, userId: UUID) {
        let identity = try requireIdentity()
        guard identity.role != .service, let userId = UUID(uuidString: identity.subject) else {
            throw RPCError(code: .permissionDenied, message: "This operation requires a user.")
        }

        return (identity, userId)
    }

    /// The caller as an administrator — a person, so their user id comes too.
    @discardableResult
    public static func requireAdminIdentity() throws -> (identity: Identity, userId: UUID) {
        let (identity, userId) = try requireUserIdentity()

        guard identity.role == .admin else {
            throw RPCError(
                code: .permissionDenied,
                message: "Administrator access is required."
            )
        }

        return (identity, userId)
    }

    /// The caller as an administrator or a process: whoever may act on rows that are not their
    /// own. Granting an entitlement or creating a user is what a payment or a registration does,
    /// and the process carrying that role is admitted beside the administrator doing it by hand.
    @discardableResult
    public static func requirePrivilegedIdentity() throws -> Identity {
        let identity = try requireIdentity()
        switch identity.role {
        case .admin, .service:
            return identity
        case .user:
            throw RPCError(
                code: .permissionDenied,
                message: "Administrator or service access is required."
            )
        }
    }
}
