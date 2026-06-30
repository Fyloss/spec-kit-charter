# Package API

The API gateway package manages all external-facing API endpoints.

## API Design

- RESTful design principles
- OpenAPI 3.0 specification required for all endpoints
- Versioning via URL path prefix (e.g., /v1/, /v2/)

## Rate Limiting

- Default rate limit: 100 requests per minute per client
- Rate limit headers must be included in all responses
- Custom limits configurable per client tier
