//
//  IdentityAuthenticator.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import Identity
import Hummingbird
import HummingbirdAuth

/// Resolves the caller's ``Identity`` from the request's bearer token and makes it available for
/// the rest of the request.
///
/// It does both halves of that in one pass. The identity goes on the request context, where
/// `IsAuthenticatedMiddleware` and the route handlers read it, and it is bound to
/// ``IdentityContext/current`` alongside the token, which is what lets a handler call another
/// service as the same caller without threading the token through every signature it passes
/// through on the way.
///
/// That is why this is a `RouterMiddleware` rather than an `AuthenticatorMiddleware`:
/// `authenticate` returns before the route handler runs, leaving no scope in which to bind a task
/// local the handler would still see. `handle` wraps the rest of the chain, so it has one.
///
/// It identifies the caller without requiring there to be one. A request carrying no token
/// continues anonymously, which is what an open route needs — logging in and registering mint the
/// first token and have no caller yet. Turning away an anonymous request is
/// `IsAuthenticatedMiddleware`'s job, added to the routes that are protected.
/// ``IdentityServerInterceptor`` draws the same line for gRPC.
public struct IdentityAuthenticator<Context>: RouterMiddleware where Context: AuthRequestContext<Identity> {
    private let verifier: IdentityVerifier

    public init(verifier: IdentityVerifier) {
        self.verifier = verifier
    }

    /// Passes a request with no token straight through, and refuses one whose token does not
    /// verify rather than reading it as anonymous.
    ///
    /// Absent and invalid are not the same thing: one is a caller who never claimed to be
    /// anyone, the other is a claim that failed. Reading the second as anonymous would turn an
    /// expired token into a silent loss of privileges on an open route, and hide a misconfigured
    /// client whose credentials nothing ever looks at.
    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let token = request.headers.bearer?.token else {
            return try await next(request, context)
        }

        let identity = try await verifyIdentity(for: token)
        var context = context
        context.identity = identity
        return try await IdentityContext.withIdentity(identity, token: token) {
            return try await next(request, context)
        }
    }

    /// The rejection is an `HTTPError` rather than the verification error, which carries no status
    /// and would be reported as a server fault — the wrong answer for the most ordinary request a
    /// client makes: one holding a token that has expired.
    private func verifyIdentity(for token: String) async throws -> Identity {
        do {
            return try await verifier.verify(token: token)
        } catch {
            throw HTTPError(.unauthorized, message: "Invalid or expired token.")
        }
    }
}
