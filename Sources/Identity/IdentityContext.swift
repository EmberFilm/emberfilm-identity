//
//  IdentityContext.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/21/26.
//

public struct IdentityContext: Sendable {
    public let identity: Identity
    public let token: String

    private init(identity: Identity, token: String) {
        self.identity = identity
        self.token = token
    }

    @TaskLocal public static var current: IdentityContext?

    public static func withIdentity<T>(
        _ identity: Identity,
        token: String,
        isolation: isolated (any Actor)? = #isolation,
        operation: () async throws -> T
    ) async rethrows -> T {
        let context = IdentityContext(identity: identity, token: token)
        return try await $current.withValue(context, operation: operation, isolation: isolation)
    }
}
