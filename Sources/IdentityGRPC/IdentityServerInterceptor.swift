//
//  IdentityServerInterceptor.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import Identity
import JWTKit
import GRPCCore

/// Rejects RPCs without a valid access token and binds the caller's ``Identity`` for the handler.
///
/// Apply it only to the RPCs that require a caller. Registration and authentication RPCs mint
/// the first token and must stay unauthenticated.
public struct IdentityServerInterceptor: ServerInterceptor {
    private static let headerName = "authorization"
    private static let scheme = "Bearer "

    private let keyCollection: JWTKeyCollection

    public init(keyCollection: JWTKeyCollection) {
        self.keyCollection = keyCollection
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next: @Sendable (
            _ request: StreamingServerRequest<Input>,
            _ context: ServerContext
        ) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard let header = request.metadata[stringValues: Self.headerName].first(where: { $0.hasPrefix(Self.scheme) }) else {
            throw RPCError(code: .unauthenticated, message: "An access token is required.")
        }

        do {
            let identity = try await keyCollection.verify(String(header.dropFirst(Self.scheme.count)), as: Identity.self)

            return try await Identity.$current.withValue(identity) {
                try await next(request, context)
            }
        } catch {
            throw RPCError(
                code: .unauthenticated,
                message: "The access token is invalid or expired."
            )
        }
    }
}
