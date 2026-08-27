//
//  AuthenticationServiceIdentityClient.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

import AuthenticationProtos
import GRPCCore
import Identity

/// `IssueServiceToken` behind the `ServiceIdentityClient` a `ServiceIdentitySession` drives.
///
/// This is the one place the identity package meets the authentication contract, and it is its
/// own product so that the rest of the package does not: `Identity`, `IdentityGRPC` and
/// `IdentityHTTP` link nothing from `emberfilm-protos`, and a service that only verifies tokens
/// never pulls the contract in. Every process that acts as itself — a worker, a service reacting
/// to a webhook — links `ServiceIdentity` and nothing of the authentication service's own.
///
/// The error mapping is the part that matters. `unauthenticated` from the issuer means the
/// credentials were refused, and no retry will change that; `unavailable` and a missed deadline
/// mean the issuer could not be reached, which says nothing about the credentials. Collapsing the
/// two would make an outage look like a revocation.
public struct AuthenticationServiceIdentityClient<Transport: ClientTransport>: ServiceIdentityClient {
    private let client: Emberfilm_Authentication_V1_AuthenticationService.Client<Transport>
    private let callOptions: CallOptions

    /// The deadline bounds how long a process waits on the issuer. Every call the process makes
    /// as itself waits on this first, so a hung issuer must fail it rather than hang it.
    public init(client: GRPCClient<Transport>, timeout: Duration = .seconds(5)) {
        self.client = Emberfilm_Authentication_V1_AuthenticationService.Client(wrapping: client)
        var callOptions = CallOptions.defaults
        callOptions.timeout = timeout
        self.callOptions = callOptions
    }

    public func issueToken(
        credentials: ServiceIdentityCredentials
    ) async throws(ServiceIdentityClientError) -> ServiceIdentityToken {
        var request = Emberfilm_Authentication_V1_IssueServiceTokenRequest()
        request.clientID = credentials.clientId
        request.clientSecret = credentials.clientSecret
        do {
            let response = try await client.issueServiceToken(request, options: callOptions)
            return ServiceIdentityToken(
                accessToken: response.accessToken,
                expirationDate: response.expirationDate.date
            )
        } catch let error as RPCError where error.code == .unauthenticated {
            throw ServiceIdentityClientError(.invalidCredentials, underlyingError: error)
        } catch let error as RPCError where error.code == .unavailable || error.code == .deadlineExceeded {
            throw ServiceIdentityClientError(.unavailable, underlyingError: error)
        } catch {
            throw ServiceIdentityClientError(.unknown, underlyingError: error)
        }
    }
}
