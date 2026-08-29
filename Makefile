SHELL := /usr/bin/env bash
ENV ?= staging
SCENARIO ?= failover
ENV_DIR := envs/$(ENV)

.DEFAULT_GOAL := help
.PHONY: help init plan apply destroy fmt validate lint verify drill maintenance output

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@printf '\n  ENV=staging|production (default: staging)\n'
	@printf '  SCENARIO=failover|autoscale|rollback|restore|all (default: failover)\n\n'

init: ## Initialise the environment
	terraform -chdir=$(ENV_DIR) init -input=false

plan: init ## Show what would change
	terraform -chdir=$(ENV_DIR) plan -input=false

apply: init ## Apply the environment
	terraform -chdir=$(ENV_DIR) apply -input=false

destroy: init ## Destroy the environment
	terraform -chdir=$(ENV_DIR) destroy -input=false

output: init ## Show the environment outputs
	terraform -chdir=$(ENV_DIR) output

fmt: ## Format the code
	terraform fmt -recursive

validate: ## Validate every configuration
	@for dir in bootstrap envs/staging envs/production; do \
		echo "--- $$dir ---"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

lint: ## Check formatting, configuration and shell syntax
	terraform fmt -recursive -check -diff
	@$(MAKE) --no-print-directory validate
	@docker run --rm -v "$$PWD:/data" -w /data ghcr.io/terraform-linters/tflint --recursive
	@docker run --rm -v "$$PWD:/mnt" -w /mnt koalaman/shellcheck:latest scripts/*.sh
	@echo "all checks passed"

verify: ## Check that the environment is healthy
	./scripts/verify.sh $(ENV)

drill: ## Run a failure scenario against the environment
	./scripts/drill.sh $(SCENARIO) $(ENV)

maintenance: ## Run a one-off wp-cli command, CMD='wp core version'
	./scripts/maintenance-task.sh $(ENV) '$(CMD)'
