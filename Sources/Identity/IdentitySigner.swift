//
//  IdentitySigner.swift
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

public struct IdentitySigner: Sendable {
    public struct Configuration: Sendable {
        public let issuer: String
        public let privateKey: EdDSA.PrivateKey
        
        public init(issuer: String, privateKey: EdDSA.PrivateKey) {
            self.issuer = issuer
            self.privateKey = privateKey
        }
    }

    private let keys: JWTKeyCollection
    private let configuration: Configuration

    public init(configuration: Configuration) async throws {
        self.configuration = configuration

        let keys = JWTKeyCollection()
        await keys.add(eddsa: configuration.privateKey)
        self.keys = keys
    }

    public func sign(identity: Identity) async throws -> String {
        try await keys.sign(identity)
    }
}
