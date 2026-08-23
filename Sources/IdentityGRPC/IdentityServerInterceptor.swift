//
//  IdentityServerInterceptor.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import Identity
import GRPCCore

/// Identifies the caller of an RPC from its bearer token, without requiring there to be one.
///
/// Apply it to every RPC. It binds ``IdentityContext/current`` when a token is present and
/// leaves it `nil` when there is none, which is what an unprotected RPC needs — registration
/// and authentication mint the first token and have no caller yet. Insisting on a caller is a
/// separate decision, left to the handler that needs one: it reads ``IdentityContext/current``
/// and refuses a `nil` one. That is the same split as `AuthenticatorMiddleware` and
/// `IsAuthenticatedMiddleware` on the HTTP side — identifying a caller and requiring one are
/// not the same job.
///
/// A token that is present but does not verify is refused rather than read as anonymous.
/// Absent and invalid are not the same thing: one is a caller who never claimed to be anyone,
/// the other is a claim that failed. Quietly downgrading the second would turn an expired token
/// into a silent loss of privileges on an unprotected RPC, and hide a misconfigured client
/// whose credentials nothing ever looks at.
///
/// The token is bound alongside the identity because a handler has no way to reach it:
/// `ServerContext` carries the method descriptor and the peers, not the request metadata.
/// ``IdentityClientInterceptor`` reads it back when the handler calls another service.
public struct IdentityServerInterceptor: ServerInterceptor {
    private let verifier: IdentityVerifier

    public init(verifier: IdentityVerifier) {
        self.verifier = verifier
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next: @Sendable (
            _ request: StreamingServerRequest<Input>,
            _ context: ServerContext
        ) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard let token = request.metadata.bearer else {
            return try await next(request, context)
        }

        let identity = try await verifyIdentity(for: token)

        return try await IdentityContext.withIdentity(identity, token: token) {
            try await next(request, context)
        }
    }

    private func verifyIdentity(for token: String) async throws -> Identity {
        do {
            return try await verifier.verify(token: token)
        } catch {
            throw RPCError(code: .unauthenticated, message: "Invalid or expired token.")
        }
    }
}
