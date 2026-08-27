//
//  ServiceIdentityCredentials.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/27/26.
//

/// What a process presents to obtain a token: the id its credential was issued under and the
/// secret that was printed once when it was.
public struct ServiceIdentityCredentials: Sendable {
    public let clientId: String
    public let clientSecret: String

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}
