# Authentication Package Constitution

## Identity

- Treat authentication as the verification of identity only.
- Keep authentication separate from authorization and business logic.
- Use a single, well-defined authentication flow for each supported identity provider.
- Ensure authentication behavior is consistent across all entry points.

## Session & Token Management

- Validate every credential and token before trusting it.
- Define clear token lifecycle rules, including issuance, renewal, and expiration.
- Support token revocation where applicable.
- Ensure authentication state is deterministic and consistent.

## Authentication Flows

- Support only explicitly approved authentication mechanisms.
- Fail authentication securely when validation cannot be completed.
- Require explicit verification for identity-sensitive operations.
- Avoid implicit authentication or automatic trust escalation.

## Identity Context

- Expose authenticated identity through a consistent interface.
- Propagate only the identity information required by downstream components.
- Clearly distinguish authenticated, anonymous, and system identities.
- Ensure identity context remains immutable during request processing.

## Extensibility

- Keep authentication providers interchangeable through well-defined abstractions.
- Isolate provider-specific behavior from application logic.
- Allow new authentication methods to be added without changing existing consumers.

## Auditability

- Record significant authentication lifecycle events.
- Ensure authentication decisions can be reconstructed for troubleshooting.
- Make authentication failures distinguishable from authorization failures.

## Before Completing Any Change

- Verify all authentication flows remain consistent.
- Confirm identity information is propagated correctly.
- Review token and session lifecycle behavior.
- Validate failure scenarios and recovery paths.
- Ensure authentication changes do not impact authorization behavior.