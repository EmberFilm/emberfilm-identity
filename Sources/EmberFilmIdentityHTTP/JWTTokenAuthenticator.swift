//
//  JWTTokenAuthenticator.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import EmberFilmIdentity
import Hummingbird
import HummingbirdAuth

public struct JWTTokenAuthenticator<Context>: AuthenticatorMiddleware where Context: AuthRequestContext<JWTUserPayload> {
    private let tokenVerifier: JWTTokenVerifier

    public init(tokenVerifier: JWTTokenVerifier) {
        self.tokenVerifier = tokenVerifier
    }

    public func authenticate(request: Request, context: Context) async throws -> JWTUserPayload? {
        guard let token = request.headers.bearer?.token else {
            return nil
        }
        return try? await tokenVerifier.verify(token)
    }
}
