//
//  IdentityClientInterceptor.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/21/26.
//

import Identity
import GRPCCore

/// Attaches the calling request's access token to an outgoing RPC.
///
/// This is the other half of ``IdentityServerInterceptor``: that one lifts the token off an
/// incoming call, this one puts it back on the next one, so one token identifies the caller at
/// every service in the chain. It is resent unchanged rather than reissued because only the
/// service that signed it can produce another.
///
/// Register it on the `GRPCClient` rather than per call, so a service cannot forget it.
public struct IdentityClientInterceptor: ClientInterceptor {
    public init() {}

    /// Calls made outside a caller's request — startup work, a workflow activity, anything with
    /// no inbound token — go out unauthenticated rather than failing here. A process that should
    /// identify itself on such calls makes them through a separate client carrying
    /// ``ServiceIdentityInterceptor``, which speaks as the process on every call.
    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (
            _ request: StreamingClientRequest<Input>,
            _ context: ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        guard let token = IdentityContext.current?.token else {
            return try await next(request, context)
        }

        var request = request
        request.metadata.bearer = token

        return try await next(request, context)
    }
}
