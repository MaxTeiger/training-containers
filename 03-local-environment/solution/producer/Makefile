VERSION ?= latest
IMAGE ?= producer:$(VERSION)

.DEFAULT_TARGET = help

## help: Display list of commands
.PHONY: help
help: Makefile
	@sed -n 's|^##||p' $< | column -t -s ':' | sed -e 's|^| |'

## build: Build a container image
.PHONY: build
build:
	docker build . -t ${IMAGE}

## run: Run the producer
.PHONY: run
run:
	docker run -p 8080:8080 ${IMAGE}

## live: Run the producer with live reloading
.PHONY: live
live:
	docker build . -t ${IMAGE}-dev --target=development
	docker run -p 8080:8080 -v $$PWD:/app ${IMAGE}-dev
