//
//  ServiceIdentityInterceptor.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

import GRPCCore
import Identity

/// Presents the process's own identity on an outgoing RPC.
///
/// The counterpart of ``IdentityClientInterceptor``, which forwards a caller's token: this one
/// attaches the token the process obtained for itself, from a ``ServiceIdentitySession`` that
/// keeps it current. A worker, a service acting on a webhook, anything that calls with no inbound
/// request behind it, uses this.
///
/// A client carrying this interceptor speaks as the process on every call, whatever identity is
/// bound at the time. A process that also forwards callers — a request handler relaying a
/// person's token — does so through a separate client carrying ``IdentityClientInterceptor``;
/// registering both on one client would leave the header to whichever ran last.
///
/// A token the receiving service refuses as `unauthenticated` is refreshed and the call retried
/// once. Once, because a second refusal means the credential itself is no good, and that is the
/// answer to return.
public struct ServiceIdentityInterceptor<Client: ServiceIdentityClient>: ClientInterceptor {
    private let session: ServiceIdentitySession<Client>

    public init(session: ServiceIdentitySession<Client>) {
        self.session = session
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (
            _ request: StreamingClientRequest<Input>,
            _ context: ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        var request = request
        request.metadata.bearer = try await session.accessToken

        let response = try await next(request, context)
        // Only a refusal at acceptance is retried: the server rejected the call before any
        // message crossed, so the request can be sent again whole.
        if case .failure(let error) = response.accepted, error.code == .unauthenticated {
            request.metadata.bearer = try await session.refresh().accessToken
            return try await next(request, context)
        }

        return response
    }
}

extension ServiceIdentityClientError: RPCErrorConvertible {
    /// Refused credentials are `unauthenticated` — the process's own standing is gone, and the
    /// call would have been refused with that code had it been sent. An unreachable issuer is
    /// `unavailable`, which is retryable and names the right thing.
    public var rpcErrorCode: RPCError.Code {
        switch code {
        case .invalidCredentials:
            .unauthenticated
        case .unavailable, .unknown:
            .unavailable
        }
    }

    public var rpcErrorMessage: String {
        switch code {
        case .invalidCredentials:
            "The service credentials were refused."
        case .unavailable, .unknown:
            "The identity issuer could not be reached."
        }
    }
}
