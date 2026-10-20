.DEFAULT_GOAL := help

help: ## List commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}'

setup: ## Install deps, create local secrets, migrate the local D1 database
	cd api && npm ci
	cd admin && npm ci
	@test -f api/.dev.vars || (cp api/.dev.vars.example api/.dev.vars && cd api && node scripts/gen-keys.mjs | grep -v JWT_KEY_ID >> .dev.vars)
	cd api && npm run db:migrate:local
	@echo "Ready. Run 'make api' and 'make admin' in two terminals."

api: ## Run the API Worker locally on http://localhost:8787 (D1/KV/Queues/Workflows simulated)
	cd api && npm run dev

admin: ## Run the admin on http://localhost:3000 (talks to the local API)
	cd admin && API_BASE_URL=http://localhost:8787 npm run dev

admin-preview: ## Run the admin as a Worker (OpenNext) on :8788, bound to the local API Worker
	cd admin && npm run preview

migration: ## Generate a D1 migration from schema changes: make migration m=add_x_to_y
	cd api && npx drizzle-kit generate --name $(m)

migrate-local: ## Apply migrations to the local D1 database
	cd api && npm run db:migrate:local

check-api: ## Lint, type-check, format-check and test the API (tests run inside workerd)
	cd api && npm run check

check-admin: ## Lint, type-check, test and build the admin
	cd admin && npm run check

check-mobile: ## Analyze and test the Flutter app
	cd mobile && dart format --set-exit-if-changed lib test && flutter analyze && flutter test

check: check-api check-admin ## Everything CI runs (mobile needs Flutter: make check-mobile)

deploy-staging: ## Migrate + deploy API and admin to staging (needs `npx wrangler login`)
	cd api && npm run db:migrate:staging && npm run deploy:staging
	cd admin && npm run deploy:staging

deploy-production: ## Migrate + deploy API and admin to production
	cd api && npm run db:migrate:production && npm run deploy:production
	cd admin && npm run deploy:production

.PHONY: help setup api admin admin-preview migration migrate-local check check-api check-admin check-mobile deploy-staging deploy-production
