.DEFAULT_GOAL := help
.PHONY: help

build:: ## build qos-control
	docker build --force-rm --no-cache -t qos-control:latest . | tee build.log

tty: ## run qos-control (need privileged)
	docker run -it --rm --privileged qos-control /bin/bash

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


