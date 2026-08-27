//
//  ServiceIdentitySession.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A process's standing with the issuer, kept current.
///
/// It holds the credentials and the token they last bought, and hands out the token on demand.
/// A token within five minutes of expiry is replaced before it is handed out, so a receiving
/// service never sees one about to lapse. One exchange is in flight at a time: callers that
/// arrive while it runs wait on it rather than each asking the issuer.
public actor ServiceIdentitySession<Client: ServiceIdentityClient> {
    private let client: Client
    private let credentials: ServiceIdentityCredentials
    private var state: State = .unauthenticated

    public enum State: Sendable {
        /// No token is held: none obtained yet, or the last exchange failed.
        case unauthenticated
        /// A token is held.
        case authenticated(ServiceIdentityToken)
        /// An exchange is in flight, and every caller waits on it.
        case authenticating(Task<ServiceIdentityToken, any Error>)
    }

    public init(client: Client, credentials: ServiceIdentityCredentials) {
        self.client = client
        self.credentials = credentials
    }

    /// A token good for the call about to be made, obtained or refreshed first if need be.
    public var accessToken: String {
        get async throws(ServiceIdentityClientError) {
            switch state {
            case .authenticated(let token) where !token.isExpiring(within: 5 * 60):
                return token.accessToken

            case .authenticating(let task):
                let token = try await settle(task)
                return token.accessToken

            case .authenticated, .unauthenticated:
                let token = try await refresh()
                return token.accessToken
            }
        }
    }

    /// Exchanges the credentials for a new token, joining an exchange already in flight rather
    /// than starting a second.
    ///
    /// Call it at startup so that a wrong secret or an unreachable issuer fails there, naming the
    /// problem, rather than at the first RPC. The interceptor calls it when a receiving service
    /// refuses the token the session believed was good.
    @discardableResult
    public func refresh() async throws(ServiceIdentityClientError) -> ServiceIdentityToken {
        if case .authenticating(let task) = state {
            return try await settle(task)
        }

        let task = Task { [client, credentials] in
            try await client.issueToken(credentials: credentials)
        }
        state = .authenticating(task)
        return try await settle(task)
    }

    /// Waits for an exchange and records how it ended.
    private func settle(
        _ task: Task<ServiceIdentityToken, any Error>
    ) async throws(ServiceIdentityClientError) -> ServiceIdentityToken {
        do {
            let token = try await task.value
            record(.authenticated(token), for: task)
            return token
        } catch let error as ServiceIdentityClientError {
            record(.unauthenticated, for: task)
            throw error
        } catch {
            record(.unauthenticated, for: task)
            throw ServiceIdentityClientError(.unknown, underlyingError: error)
        }
    }

    /// Only the exchange the session is still waiting on may decide its state. Several callers
    /// wait on one task and resume in turn; the first to resume records the outcome, and a
    /// later one must not overwrite whatever has happened since — a newer exchange, say.
    private func record(_ outcome: State, for task: Task<ServiceIdentityToken, any Error>) {
        if case .authenticating(let current) = state, current == task {
            state = outcome
        }
    }
}
