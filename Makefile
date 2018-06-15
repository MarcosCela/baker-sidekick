## Makefile directives
.PHONY: build push help
.DEFAULT_GOAL := help
IMAGE := markoscl/baker-sidekick:latest
help: ## Shows this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Builds the docker image locally
	@echo "Building $(IMAGE) now!"
	@docker build -t $(IMAGE) .

push: ## Push the image to the dockerhub registry
	@docker push $(IMAGE)

test: ## Test the image locally by using docker compose
	@echo "Going to test image with docker compose..."
	@docker-compose -f testing/docker-compose.yaml down -v
	@docker-compose -f testing/docker-compose.yaml up --force-recreate
