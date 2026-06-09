# 3-5 Minute Demo Checklist

Use this as the interview walkthrough path after `make up` finishes.

## 1. Prove The Stack Is Integrated

```bash
make smoke
```

Point out what the smoke check proves:

- Dashboard is reachable.
- Telemetry API health is reachable directly.
- Gateway health is reachable and Redis is online.
- Protected API routes reject unauthenticated requests with `401`.
- Login works through the gateway.
- Authenticated vehicle fetch returns the seeded Ford F-150.
- Gateway metrics and rate-limit headers are present.

## 2. Show The Product Path

1. Open `http://localhost:15173`.
2. Sign in with `admin / password123`.
3. Open the seeded Ford F-150.
4. Show telemetry summary, ECUs, signals, and event timeline.
5. Mention that browser requests flow through the gateway before reaching the API and Postgres.

## 3. Show Observability

```bash
make metrics
```

Call out `gateway_requests_total` and the rate-limit counters after making UI or API requests.

## 4. Show Rate Limiting

For a faster demo, set these in `.env`:

```bash
RATE_LIMIT_CAPACITY=5
RATE_LIMIT_WINDOW_SECONDS=60
```

Restart the stack:

```bash
make down
make up
```

Then repeat a gateway request until it returns `429`:

```bash
for i in {1..10}; do curl -i http://localhost:18080/health; done
```

Point out:

- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`
- `Retry-After`

## 5. Show Failure Behavior

Stop Redis to show fail-closed rate limiting:

```bash
docker compose stop redis
curl -i http://localhost:18080/api/v1/vehicles
docker compose start redis
```

Stop the telemetry API to show upstream failure handling:

```bash
docker compose stop telemetry-api
curl -i http://localhost:18080/api/v1/health
docker compose start telemetry-api
```

Close with the architecture summary: React dashboard, FastAPI gateway, Redis token buckets, FastAPI telemetry API, worker, migrations, seed data, and Postgres.
