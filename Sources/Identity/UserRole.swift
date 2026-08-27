//
//  UserRole.swift
//  emberfilm-identity
//
//  Created by Zaid Rahhawi on 8/23/26.
//

/// What the subject of an ``Identity`` is allowed to do.
///
/// It lives here rather than in the service that owns users because it is part of the token's
/// shape: every service that verifies an ``Identity`` reads this claim, and a copy per service
/// would be the same contract restated once per reader, wrong at whichever one drifted.
///
/// Carrying it in the token is what lets a service authorize a caller without asking the users
/// service who they are. The cost is that a change of role does not take effect until the token
/// is next refreshed, which is the same bound that already applies to a revoked session.
public enum UserRole: String, Codable, Sendable {
    case user
    case admin

    /// A process acting for itself — a worker, a service reacting to a webhook — rather than a
    /// person acting on their own account.
    ///
    /// The subject of such a token is the name the credential was issued under, not a user id.
    /// An RPC that only makes sense for a person refuses this role before it reads the subject:
    /// the role is the test, because the subject's shape proves nothing — a credential can be
    /// issued under any name. Whether a service may reach a given RPC at all is the receiving
    /// service's decision, made per RPC like the admin check.
    case service
}
