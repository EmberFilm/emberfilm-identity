//
//  IdentityVerifier.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/21/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import JWTKit

public struct IdentityVerifier: Sendable {
    public struct Configuration: Sendable {
        public let publicKey: EdDSA.PublicKey
        
        public init(publicKey: EdDSA.PublicKey) {
            self.publicKey = publicKey
        }
    }

    private let keys: JWTKeyCollection
    private let configuration: Configuration
    
    public init(configuration: Configuration) async throws {
        self.configuration = configuration

        let keys = JWTKeyCollection()
        await keys.add(eddsa: configuration.publicKey)
        self.keys = keys
    }

    public func verify(token: String) async throws -> Identity {
        try await keys.verify(token, as: Identity.self)
    }
}
