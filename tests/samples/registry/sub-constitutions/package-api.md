# API Package Constitution

## API Design

- Design APIs around business capabilities, not implementation details.
- Keep endpoints consistent in naming, structure, and behavior.
- Prefer explicit and predictable contracts over implicit behavior.
- Ensure APIs are backward compatible whenever possible.
- Version breaking changes using the project's versioning strategy.

## Request & Response Contracts

- Define clear request and response schemas for every endpoint.
- Use consistent naming conventions across all payloads.
- Return structured, machine-readable error responses.
- Support pagination, filtering, and sorting consistently where applicable.
- Avoid exposing internal implementation details in API responses.

## HTTP Semantics

- Use HTTP methods according to their intended semantics.
- Return appropriate HTTP status codes for every outcome.
- Make safe operations idempotent when possible.
- Ensure idempotency for operations that may be retried.

## Documentation

- Keep API documentation synchronized with the implementation.
- Document every endpoint, parameter, response, and error.
- Provide meaningful examples for common use cases.
- Clearly document breaking changes and deprecations.

## Evolution

- Prefer additive changes over breaking changes.
- Mark deprecated endpoints and fields before removal.
- Define a migration path for breaking changes.
- Preserve client compatibility whenever reasonably possible.

## Observability

- Assign a unique request or correlation identifier to each request.
- Produce meaningful metrics for API usage and reliability.
- Ensure failures can be diagnosed without exposing implementation details.

## Before Completing Any Change

- Verify the API contract remains consistent.
- Confirm documentation reflects the implementation.
- Review compatibility with existing clients.
- Validate success, error, and edge-case responses.
- Ensure any API change has a clear migration strategy if required.