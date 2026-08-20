//
//  Identity+current.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/20/26.
//

/// The verified caller for the RPC being handled.
///
/// `IdentityServerInterceptor` binds this for the duration of the handler, so a service
/// reads `Identity.current` instead of parsing metadata itself. It is `nil` on RPCs the
/// interceptor was not applied to, and on HTTP requests, where the identity is carried by
/// the request context instead.
///
/// The value is bound around the handler call, which covers unary RPCs. A streaming
/// handler that produces messages after returning its response must capture the identity
/// before it starts writing.
public extension Identity {
    @TaskLocal static var current: Identity?
}
