.DEFAULT_GOAL := help
COMPOSE := docker compose -f infra/docker-compose.yml

help: ## List commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-16s\033[0m %s\n", $$1, $$2}'

setup: ## Install all dependencies (backend, admin) and create .env
	@test -f .env || cp .env.example .env
	cd backend && uv sync
	cd admin && npm ci
	@echo "Now run: make keys  (and paste the output into .env)"

keys: ## Print fresh ES256 JWT keys for .env
	cd backend && uv run python scripts/gen_keys.py

up: ## Start Postgres, Redis, API and worker (migrations run on start)
	$(COMPOSE) up -d --build

down: ## Stop local services
	$(COMPOSE) down

logs: ## Tail API and worker logs
	$(COMPOSE) logs -f api worker

db-up: ## Start only Postgres and Redis (run the API on the host)
	$(COMPOSE) up -d postgres redis

api: ## Run the API on the host with reload
	cd backend && uv run uvicorn app.main:app --reload

admin: ## Run the admin dashboard on http://localhost:3000
	cd admin && npm run dev

migrate: ## Apply migrations
	cd backend && uv run alembic upgrade head

seed: ## Load showcase data (owner, sources, 60 cards, ads, review queue)
	cd backend && uv run python scripts/seed.py

migration: ## Create a migration: make migration m="add x to y"
	cd backend && uv run alembic revision --autogenerate -m "$(m)"

check-backend: ## Lint, format, type-check and test the backend
	cd backend && uv run ruff check . && uv run ruff format --check . && uv run mypy app && uv run pytest

check-admin: ## Lint, type-check, test and build the admin
	cd admin && npm run check

check-mobile: ## Analyze and test the Flutter app
	cd mobile && dart format --set-exit-if-changed lib test && flutter analyze && flutter test

check: check-backend check-admin ## Run every check CI runs (mobile needs Flutter: make check-mobile)

.PHONY: help setup keys up down logs db-up api admin migrate migration seed check check-backend check-admin check-mobile
