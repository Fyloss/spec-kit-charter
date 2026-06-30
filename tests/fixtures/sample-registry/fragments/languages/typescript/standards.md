# TypeScript Standards

## Type Safety

- Strict mode must be enabled in tsconfig.json
- `any` type usage must be justified and documented
- Prefer interfaces over type aliases for object shapes

## Code Style

- Use ESLint with the organization's shared config
- Prettier for formatting with consistent settings
- Maximum function length: 50 lines
- Maximum file length: 300 lines

## Dependencies

- Pin exact versions in package.json
- Review and approve all new dependencies
- Run `npm audit` as part of CI pipeline
