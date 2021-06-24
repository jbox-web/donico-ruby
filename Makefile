# Ensure that every command in this Makefile
# will run with bash instead of the default sh
SHELL := /usr/bin/env bash

# Gem config
GITLAB_PACKAGE_REGISTRY = https://gitlab.thetuxhouse.org/api/v4/projects/63/packages/rubygems

# Dev tools config
COMMIT_LINTER = harbor.jbox-cloud.fr/jbox/base/amd64/buster/commitlint:latest

################
# Public tasks #
################

# This is the default task
all: help

deps: ## Install dependencies
	bin/bundle install

test: ## Run RSpec
	bin/rake spec

build: ## Build Donico gem
	bin/rake build DONICO_RELEASE=true

release: ## Push Donico gem
# 	bin/rake release DONICO_RELEASE=true RUBYGEMS_HOST=$(GITLAB_PACKAGE_REGISTRY)
# TODO: fix me when Gitlab issue is fixed
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/333607
	curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file pkg/donico-$(shell echo ${CI_COMMIT_REF_NAME} | sed 's/^.//').gem "https://gitlab.thetuxhouse.org/api/v4/projects/63/packages/generic/donico/${CI_COMMIT_REF_NAME}/donico-$(shell echo ${CI_COMMIT_REF_NAME} | sed 's/^.//').gem"

.PHONY: all deps test build release


################
# LINT section #
################

lint-commits: ## Lint commits
	docker run --pull always --rm -v "${PWD}:/app" $(COMMIT_LINTER) commitlint /app && echo "Commits are OK!"

lint-project: ## Lint project
	bin/rubocop

.PHONY: lint-commits lint-project


#################
# Private tasks #
#################

help:
	@grep -E '^[0-9a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
