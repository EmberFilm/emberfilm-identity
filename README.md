# emberfilm-identity

Shared identity for the EmberFilm microservices: one signed access token that means the same
thing at every hop of a request.

One service holds the private key and mints tokens. Every other service is configured with the
matching public key and can read a token but never produce one. When a service calls another
while handling a request, the caller's token rides along, so the identity established at the
edge is still the identity at the far end of the chain.

## Modules

| Product | Depends on | What it gives you |
| --- | --- | --- |
| `Identity` | JWTKit | The `Identity` claims, `IdentitySigner`, `IdentityVerifier`, and the `IdentityContext` task local |
| `IdentityGRPC` | `Identity`, GRPCCore | `IdentityServerInterceptor` and `IdentityClientInterceptor` |
| `IdentityHTTP` | `Identity`, Hummingbird | `IdentityAuthenticator` router middleware |

Link only the transports you speak. A gRPC-only service takes `Identity` and `IdentityGRPC`.

## Requirements

Swift 6.3, Swift 6 language mode, macOS 15 or later.

## Installation

```swift
.package(url: "https://github.com/EmberFilm/emberfilm-identity.git", from: "0.5.0")
```

```swift
.target(
    name: "MyService",
    dependencies: [
        .product(name: "Identity", package: "emberfilm-identity"),
        .product(name: "IdentityGRPC", package: "emberfilm-identity"),
    ]
)
```

## Keys

Tokens are EdDSA (Ed25519) JWTs. Generate the pair once:

```sh
openssl genpkey -algorithm ed25519 -out private.pem
openssl pkey -in private.pem -pubout -out public.pem
```

The private key is a secret and belongs to the signing service alone. The public key is not a
secret and goes to every other service.

## Signing

Only the service that owns the private key builds an `IdentitySigner`.

```swift
import Identity
import JWTKit

let signer = try await IdentitySigner(
    configuration: IdentitySigner.Configuration(
        issuer: "emberfilm-authentication",
        privateKey: try EdDSA.PrivateKey(pem: privateKeyPEM)
    )
)
```

Minting is two steps. `makeIdentity` states who the token is for, what they may do, and how long
it lasts; the issuer and issued-at are the signer's, not the caller's. It returns the `Identity`
rather than signing in one go so you can report the expiration you actually signed, instead of
reading the clock a second time and getting a different answer.

```swift
let identity = signer.makeIdentity(subject: userID, role: user.role, expiration: 900)
let accessToken = try await signer.signIdentity(identity)

return AccessToken(value: accessToken, expiresAt: identity.expiration.value)
```

`IdentitySigner.makeIdentity` is the only way to obtain an `Identity`. The claims cannot be
assembled anywhere else, so nothing in the process can hand `signIdentity(_:)` something it did
not build.

`role` is the caller's to state, because only the caller has looked the subject up — the signer
attests a claim, it does not know what is true of a user.

## Verifying

Every service — including the signing one — builds a verifier from the public key.

```swift
let verifier = try await IdentityVerifier(
    configuration: IdentityVerifier.Configuration(
        publicKey: try EdDSA.PublicKey(pem: publicKeyPEM)
    )
)
```

### gRPC

Apply `IdentityServerInterceptor` to every RPC, and register `IdentityClientInterceptor` on the
client rather than per call so a service cannot forget it.

```swift
import IdentityGRPC

let server = GRPCServer(
    transport: .http2NIOPosix(address: .ipv4(host: host, port: port), transportSecurity: .plaintext),
    services: [myService],
    interceptorPipeline: [
        .apply(
            IdentityServerInterceptor(verifier: verifier),
            to: .allExcluding(services: [], methods: MyService.publicMethods)
        )
    ]
)

let usersClient = GRPCClient(
    transport: try .http2NIOPosix(target: .dns(host: usersHost, port: usersPort), transportSecurity: .plaintext),
    interceptors: [IdentityClientInterceptor()]
)
```

### HTTP

`IdentityAuthenticator` needs a context conforming to `AuthRequestContext<Identity>`;
Hummingbird's `BasicAuthRequestContext<Identity>` will do.

```swift
import IdentityHTTP
import HummingbirdAuth

typealias AppRequestContext = BasicAuthRequestContext<Identity>

let router = Router(context: AppRequestContext.self)
router.add(middleware: IdentityAuthenticator(verifier: verifier))

router.group("account")
    .add(middleware: IsAuthenticatedMiddleware())
    .get { request, context in
        let identity = try context.requireIdentity()
        ...
    }
```

## Identifying a caller versus requiring one

The authenticator and the server interceptor identify the caller. Neither turns away a request
that carries no token — that is what open routes need, since logging in and registering mint the
first token and have no caller yet. Insisting on a caller is a separate decision:
`IsAuthenticatedMiddleware` on the protected HTTP routes, and, on the gRPC side, the handler
that reads `IdentityContext.current` and refuses a `nil` one.

A token that is present but does not verify is a different case and is always refused — `401` on
HTTP, `.unauthenticated` on gRPC. Reading a failed claim as anonymous would turn an expired
token into a silent loss of privileges on an open route, and hide a misconfigured client whose
credentials nothing ever checks.

## Propagating the caller

`IdentityContext.current` is a task local holding the verified `Identity` and the raw token. The
server interceptor and the HTTP authenticator bind it for the life of the request; the client
interceptor reads the token back off it and attaches it to outgoing RPCs. The same token is
resent unchanged, because only the signing service can produce another.

```swift
let identity = IdentityContext.current?.identity
```

Calls made outside a request — startup work, a workflow activity, a scheduled job — have no
inbound token and go out unauthenticated rather than failing. Whether that is acceptable is the
receiving service's decision, expressed in the RPCs it protects.

## Token shape

```json
{
  "sub": "the subject the token was minted for",
  "role": "user",
  "iss": "the signing service",
  "iat": 1755648000,
  "exp": 1755648900
}
```

`role` is a `UserRole` — `user` or `admin`. It rides in the token so a service can authorize a
caller without asking the users service who they are; the cost is that a change of role does not
take effect until the token is next refreshed.

Verification checks the signature and that the token has not expired.
