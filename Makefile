.PHONY: up down build logs ps health metrics smoke aws-smoke reset tf-fmt tf-validate

up:
	docker compose up --build

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

ps:
	docker compose ps

health:
	curl -s http://localhost:$${API_HOST_PORT:-18000}/api/v1/health
	@echo
	curl -s http://localhost:$${GATEWAY_HOST_PORT:-18080}/health
	@echo

metrics:
	curl -s http://localhost:$${GATEWAY_HOST_PORT:-18080}/metrics

smoke:
	LC_ALL=C LANG=C bash scripts/smoke.sh

aws-smoke:
	@test -n "$$DASHBOARD_URL" || (echo "Set DASHBOARD_URL=http://your-alb-dns-name before running make aws-smoke" >&2; exit 1)
	CHECK_API_DIRECT=false GATEWAY_URL=$${GATEWAY_URL:-$$DASHBOARD_URL} LC_ALL=C LANG=C bash scripts/smoke.sh

tf-fmt:
	terraform fmt -recursive infra

tf-validate:
	terraform -chdir=infra/bootstrap init -backend=false
	terraform -chdir=infra/bootstrap validate
	terraform -chdir=infra/prod-lite init -backend=false
	terraform -chdir=infra/prod-lite validate

reset:
	docker compose down -v
