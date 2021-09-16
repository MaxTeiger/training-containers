VERSION ?= latest
IMAGE ?= website:$(VERSION)
DEBUG ?= false

.DEFAULT_TARGET = help

## help: Display list of commands
.PHONY: help
help: Makefile
	@sed -n 's|^##||p' $< | column -t -s ':' | sed -e 's|^| |'

## build: Build a container image for the website
.PHONY: build
build:
	docker build . -t ${IMAGE}

## run: Run the website
.PHONY: run
run:
	docker run -p 8080:80 -e DEBUG=${DEBUG} ${IMAGE}
