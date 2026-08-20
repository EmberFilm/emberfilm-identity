//
//  IdentityAuthenticator.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import Identity
import JWTKit
import Hummingbird
import HummingbirdAuth

/// Resolves the caller's ``Identity`` from the request's bearer token.
///
/// The identity is reached through the request context rather than ``Identity/current``:
/// a middleware returns before the route handler runs, so there is no scope in which to
/// bind a task local that the handler would still see.
public struct IdentityAuthenticator<Context>: AuthenticatorMiddleware where Context: AuthRequestContext<Identity> {
    private let keyCollection: JWTKeyCollection

    public init(keyCollection: JWTKeyCollection) {
        self.keyCollection = keyCollection
    }

    /// Returns `nil` for a missing, malformed, or expired token, which the middleware reports
    /// as unauthorized. Letting the verification error escape would surface as a server error.
    public func authenticate(request: Request, context: Context) async throws -> Identity? {
        guard let token = request.headers.bearer?.token else {
            return nil
        }

        do {
            return try await keyCollection.verify(token, as: Identity.self)
        } catch {
            context.logger.debug("Rejected an access token.", metadata: ["error": "\(error)"])
            return nil
        }
    }
}
