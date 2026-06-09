.PHONY: up down build logs ps health metrics smoke reset

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

reset:
	docker compose down -v
