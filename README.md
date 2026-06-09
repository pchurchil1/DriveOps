POSTGRES_USER=app
POSTGRES_PASSWORD=app
POSTGRES_DB=telemetry
JWT_SECRET_KEY=replace-with-a-local-demo-secret
RATE_LIMIT_CAPACITY=60
RATE_LIMIT_WINDOW_SECONDS=60
UPSTREAM_TIMEOUT_SECONDS=5
POSTGRES_HOST_PORT=5433
API_HOST_PORT=18000
GATEWAY_HOST_PORT=18080
DASHBOARD_HOST_PORT=15173

## Port defaults

The integrated stack uses collision-resistant host ports so it can run beside the standalone repos:

- Dashboard: `15173`
- Gateway: `18080`
- Telemetry API: `18000`

Override them in `.env` with `DASHBOARD_HOST_PORT`, `GATEWAY_HOST_PORT`, and `API_HOST_PORT`.
