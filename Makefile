# Variables
COMPOSE_DEV = docker compose -f compose.dev.yml
COMPOSE_STG = docker compose -f compose.stg.yml
COMPOSE_PRD = docker compose -f compose.prd.yml
COMPOSE_FILE = compose.dev.yml
DOCKER_COMPOSE = $(COMPOSE_DEV)  # デフォルトは開発環境
DOCKER_EXEC = $(DOCKER_COMPOSE) exec
DOCKER_RUN = $(DOCKER_COMPOSE) run --rm
APP_SERVICE = app

.PHONY: init copy-env dev stg prd build up down restart logs status prune help db-shell collectstatic migrate

# Environment Setup
copy-env: ## Copy environment files from samples
	@if [ ! -f .env.dev ]; then \
		cp .env.dev.sample .env.dev; \
		echo ".env.dev file created from sample"; \
	else \
		echo ".env.dev file already exists"; \
	fi
	@if [ ! -f .env.stg ]; then \
		cp .env.stg.sample .env.stg; \
		echo ".env.stg file created from sample"; \
	else \
		echo ".env.stg file already exists"; \
	fi
	@if [ ! -f .env.prd ]; then \
		cp .env.prd.sample .env.prd; \
		echo ".env.prd file created from sample"; \
	else \
		echo ".env.prd file already exists"; \
	fi

# Development Commands
init: copy-env build migrate collectstatic createsuperuser ## Initialize project for first time setup
	@echo "Project initialized successfully!"

dev: ## Start development servers
	$(COMPOSE_DEV) up -d --build

stg: ## Start staging servers
	$(COMPOSE_STG) up -d --build

prd: ## Start production servers
	$(COMPOSE_PRD) up -d --build

# Docker Commands
build: ## Build or rebuild services
	$(DOCKER_COMPOSE) up -d --build

down: ## Stop all services
	@if [ -f compose.prd.yml ] && [ $$(docker compose -f compose.prd.yml ps -q | wc -l) -gt 0 ]; then \
		$(COMPOSE_PRD) down; \
	elif [ -f compose.stg.yml ] && [ $$(docker compose -f compose.stg.yml ps -q | wc -l) -gt 0 ]; then \
		$(COMPOSE_STG) down; \
	else \
		$(COMPOSE_DEV) down; \
	fi

status: ## Show status of services
	@if [ -f compose.prd.yml ] && [ $$(docker compose -f compose.prd.yml ps -q | wc -l) -gt 0 ]; then \
		$(COMPOSE_PRD) ps; \
	elif [ -f compose.stg.yml ] && [ $$(docker compose -f compose.stg.yml ps -q | wc -l) -gt 0 ]; then \
		$(COMPOSE_STG) ps; \
	else \
		$(COMPOSE_DEV) ps; \
	fi

logs: ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-app: ## View logs from Django app
	$(DOCKER_COMPOSE) logs -f $(APP_SERVICE)

# Database Commands
migrate: db-makemigrations db-migrate ## Run database migrations

db-shell: ## Access database shell
	$(DOCKER_EXEC) db psql -U postgres

db-makemigrations: ## Generate database migrations
	$(DOCKER_RUN) $(APP_SERVICE) python manage.py makemigrations

db-migrate: ## Apply database migrations
	$(DOCKER_RUN) $(APP_SERVICE) python manage.py migrate

db-flush: ## Flush database
	$(DOCKER_RUN) $(APP_SERVICE) python manage.py flush --no-input

# Static Files
collectstatic: ## Collect static files
	$(DOCKER_RUN) $(APP_SERVICE) python manage.py collectstatic --no-input

# User Management
createsuperuser: ## Create a superuser
	$(DOCKER_RUN) $(APP_SERVICE) python manage.py createsuperuser

# App Management
app-create: ## Create a new Django app (usage: make app-create name=myapp)
	$(DOCKER_RUN) $(APP_SERVICE) python manage.py startapp $(name)

# Development Shell
shell: ## Access Django shell
	$(DOCKER_EXEC) $(APP_SERVICE) python manage.py shell

# System Maintenance
prune: down ## Clean up unused Docker resources
	docker system prune -f
	docker volume prune -f
	docker network prune -f

resetdb: down ## Reset database (WARNING: destroys all data)
	docker volume rm $$(docker volume ls -q | grep "_db_data") || true
	make up
	make migrate

# Help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)



# AWS and Terraform Variables
AWS_PROFILE = r74tech
AWS_REGION ?= ap-northeast-1
ECR_REGISTRY ?= $(shell aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(AWS_REGION).amazonaws.com
COMPOSE_INFRA = docker-compose -f infra/compose.yml
TF_SERVICE = terraform
NGINX_SERVICE = nginx
DJANGO_SERVICE = app

# AWS Commands
check-env: ## Check AWS environment variables
	@echo "AWS Account ID: $$(aws sts get-caller-identity --query 'Account' --output text)"
	@echo "ECR Registry: $(ECR_REGISTRY)"

aws-login: ## Login to AWS ECR
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)

aws-vault: ## Start AWS Vault session (usage: make aws-vault profile=myprofile)
	aws-vault exec $(profile) --duration=12h

aws-build:
	cd app && docker buildx build --platform linux/amd64,linux/arm64 \
		-t $(ECR_REGISTRY)/tf-pg/django:latest \
		-f Dockerfile \
		--push .

	cd nginx && docker buildx build --platform linux/amd64,linux/arm64 \
		-t $(ECR_REGISTRY)/tf-pg/nginx:latest \
		-f Dockerfile.prd \
		--push .


# Terraform Commands
tf-plan: ## Run Terraform plan
	$(COMPOSE_INFRA) run --rm $(TF_SERVICE) plan

tf-apply: ## Apply Terraform changes
	$(COMPOSE_INFRA) run --rm $(TF_SERVICE) apply -auto-approve ${ARGS}

tf-destroy: ## Destroy Terraform resources
	$(COMPOSE_INFRA) run --rm $(TF_SERVICE) destroy -auto-approve ${ARGS}

tf-shell: ## Access Terraform shell
	$(COMPOSE_INFRA) run --rm $(TF_SERVICE) console

tf-init: ## Initialize Terraform
	$(COMPOSE_INFRA) run --rm $(TF_SERVICE) init ${ARGS}