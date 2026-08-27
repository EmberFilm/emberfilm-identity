//
//  ServiceIdentityClient.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

/// The one call a process makes to the issuer: its credentials in, a token out.
///
/// A protocol rather than a gRPC client, so that this package needs no contract package and a
/// session can be driven by a stub. The conformance that speaks `IssueServiceToken` lives with
/// the process that holds the generated client.
public protocol ServiceIdentityClient: Sendable {
    func issueToken(
        credentials: ServiceIdentityCredentials
    ) async throws(ServiceIdentityClientError) -> ServiceIdentityToken
}
