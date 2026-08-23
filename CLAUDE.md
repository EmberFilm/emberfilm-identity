# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

`emberfilm-identity` is a Swift package, not a service. It is the shared library every
EmberFilm microservice links so that one access token means the same thing at every hop of a
request. It mints tokens in the one service allowed to, verifies them everywhere else, and
carries the caller from an inbound request to the outbound calls it makes.

It is consumed over the network from `https://github.com/EmberFilm/emberfilm-identity.git`,
pinned by SemVer tag — `emberfilm-authentication` currently depends on `from: "0.4.0"`. Sibling
services live next to this directory under `emberfilm-microservices/`.

## Layout

```
Sources/
  Identity/       # transport-agnostic core: the claims, signing, verifying, the task local
  IdentityGRPC/   # grpc-swift-2 client and server interceptors
  IdentityHTTP/   # Hummingbird router middleware
```

Each directory is one SwiftPM target and one library product of the same name. `IdentityGRPC`
and `IdentityHTTP` both depend on `Identity` and never on each other — a service links only the
transports it actually speaks. Keep it that way: anything a new transport would need in common
belongs in `Identity`, not in a dependency between the two.

## Commands

```sh
swift build                      # the whole package
swift build --target IdentityGRPC
swift-format format -i -r Sources   # config in .swift-format
```

There is no test target. `swift test` builds nothing and reports nothing — do not read a clean
run as evidence that a change works.

Releases are git tags (`0.1.0` … `0.4.0`). A change consumers need is not delivered until it is
tagged and their `Package.resolved` is updated; a source edit here is invisible to
`emberfilm-authentication` until then.

## The invariants

These are the reasons the code is shaped the way it is. Most of them are load-bearing and are
easy to undo by accident.

**One service signs, everyone else verifies.** `IdentitySigner` holds an `EdDSA.PrivateKey` and
is configured only in `emberfilm-authentication`. Every other service gets the matching public
key and an `IdentityVerifier`, which reads a token but cannot produce one. Do not add a code
path that lets a verifying service mint anything.

**`Identity`'s memberwise initializer is internal on purpose.** `IdentitySigner.makeIdentity` is
the only way to obtain one, which is what makes the claims unforgeable in-process — they cannot
be assembled elsewhere and handed to `signIdentity(_:)`. Making that `init` public would quietly
delete the guarantee. Any new way to construct an `Identity` must go through the signer.

**Minting is two calls, not one.** `makeIdentity(subject:expiration:)` then
`signIdentity(_:)`. The caller almost always has to report when the token expires, and deriving
that separately would make the token and the caller's claim about it two readings of the clock
that can disagree. Do not collapse them back into a `mint` convenience.

**Identifying a caller and requiring one are separate decisions.** `IdentityAuthenticator` and
`IdentityServerInterceptor` identify; neither rejects a request that carries no token. That is
what open routes need — logging in and registering mint the first token and have no caller yet.
On the HTTP side, insisting on a caller is `IsAuthenticatedMiddleware`'s job, added to the
protected routes. This package ships no gRPC equivalent: a handler that needs a caller reads
`IdentityContext.current` and refuses a `nil` one itself.

**`UserRole` lives here, in the token.** It is part of the token's shape rather than something
the users service owns, because every verifying service reads the claim — a copy per service
would be the same contract restated once per reader. Carrying it in the token is what lets a
service authorize a caller without a round trip to the users service; the cost is that a role
change only takes effect at the next refresh, the same bound that already applies to a revoked
session. `role` is a parameter of `makeIdentity` rather than something the signer looks up: the
signer attests a claim, it does not know what is true of a user.

**Absent and invalid are not the same thing.** No token means anonymous and passes through. A
token that is present and fails to verify is refused — `401` on HTTP, `.unauthenticated` on
gRPC — never downgraded to anonymous. Downgrading would turn an expired token into a silent
loss of privileges on an open route and hide a client whose credentials nothing ever looks at.
The rejection is deliberately an `HTTPError`/`RPCError` rather than the raw JWTKit error, which
carries no status and would surface as a server fault for the most ordinary request a client
makes. The rule bites on a token-refresh RPC, which is reached precisely when the caller's token
is no good — `emberfilm-authentication` excludes those methods from the interceptor entirely
with `.apply(_:to: .allExcluding(methods:))`, so a client that attaches its access token to
every call is not refused the one call that could get it a fresh one.

**`IdentityAuthenticator` is a `RouterMiddleware`, not an `AuthenticatorMiddleware`.**
`authenticate` returns before the route handler runs, leaving no scope in which to bind a task
local the handler would still see. `handle` wraps the rest of the chain, so it has one. It sets
both `context.identity` and `IdentityContext.current`.

**Propagation is the same token, resent.** `IdentityContext.current` is a task local holding the
verified `Identity` and the raw token string; `IdentityClientInterceptor` reads the token back
off it and puts it on outgoing RPCs. It is resent unchanged rather than reissued because only
the signing service can produce another. The token is bound alongside the identity because a
gRPC handler has no other way to reach it — `ServerContext` carries the method descriptor and
the peers, not the request metadata. Register the client interceptor on the `GRPCClient`, not
per call, so a service cannot forget it.

**Bearer parsing takes the first `authorization` entry, authoritatively.** Not the first one
that happens to parse — taking the latter would let a caller hide a second credential behind one
the service ignores. The scheme is matched case-insensitively per RFC 7235, because grpc-web
clients and proxies do send `bearer`, and an unauthenticated caller is much harder to notice
than a rejected one.

## Conventions

- Swift 6 language mode, tools 6.3, macOS 15+. Everything public is `Sendable`.
- Import Foundation as `#if canImport(FoundationEssentials)` / `import FoundationEssentials`
  / `#else` / `import Foundation`, matching `IdentitySigner` and `IdentityVerifier`.
- Every type takes a nested `Configuration` struct rather than loose parameters. Reading it from
  the environment is the consuming service's job — `emberfilm-authentication` extends
  `IdentitySigner.Configuration` with a `ConfigReader` initializer. Do not pull
  `swift-configuration` in here.
- File header comments are the Xcode template form (file name, `emberfilm-identity`, author,
  date) — keep them on new files.
- `.swift-format` sets `lineLength` to 400, but the code wraps at roughly 100 columns and the
  doc comments at roughly 96. Follow the code, not the config.
- Doc comments explain *why*, at length, in full sentences — the trade-off considered, the
  failure the shape prevents. They are the main record of the design; a change that invalidates
  one should rewrite it rather than leave it standing. Match that register instead of adding
  `/// Returns the identity.`-style restatements of the signature.
