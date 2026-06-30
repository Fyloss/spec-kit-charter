# TypeScript

## Type Safety

- Enable and maintain strict TypeScript settings.
- Never use `any` unless explicitly justified and documented.
- Prefer `unknown` over `any` for untrusted data.
- Model the domain with precise types and interfaces.
- Use discriminated unions instead of boolean flags when representing variants.
- Favor immutable types and readonly properties when appropriate.

## Code Design

- Keep modules, classes, and functions focused on a single responsibility.
- Prefer composition over inheritance.
- Minimize side effects and write predictable functions.
- Avoid unnecessary abstractions and premature generalization.
- Export the smallest possible public API.

## Error Handling

- Handle expected failures explicitly.
- Do not silently swallow errors.
- Return well-defined error types or throw meaningful exceptions consistently.
- Validate external inputs before using them.

## Maintainability

- Prefer explicit, descriptive names over abbreviations.
- Remove unused code, imports, and types.
- Avoid duplicated business logic.
- Keep files reasonably small and cohesive.
- Document complex business rules rather than obvious code.

## Performance

- Optimize only when justified by measurement.
- Avoid unnecessary object allocations and repeated computations.
- Prefer built-in language features before introducing dependencies.

## Dependencies

- Minimize external dependencies.
- Choose actively maintained and well-supported packages.
- Avoid dependencies that duplicate existing platform capabilities.

## Testing

- Design code to be easily testable.
- Cover business logic with automated tests.
- Test edge cases and error paths.
- Keep tests deterministic and independent.

## Before Completing Any Change

- Ensure the code passes the TypeScript compiler with no errors.
- Eliminate unnecessary type assertions.
- Verify type inference remains clear and readable.
- Confirm public APIs are strongly typed.
- Review for simplicity, readability, and consistency.