################################################################################
# Shared targets and config
################################################################################

BASH_PATH ?= /bin/bash
TEST_DIRS := terminator/test/ tmux/test/

LINTED_SOURCE_FILES := \
  ':(top,attr:category=source language=bash)'

LINTED_TEST_FILES := \
  ':(top,attr:category=test language=bash)' \
  ':(top,attr:category=test language=bats)'

LINTED_FILES := $(LINTED_SOURCE_FILES) $(LINTED_TEST_FILES)

TEST_COMMAND := ./vendor/test/bats/bats-core/bin/bats \
  --setup-suite-file ./test/test_suite.bash \
  --pretty \
  --recursive \
  $(TEST_DIRS)

.DEFAULT_GOAL := guards
.PHONY: guards
guards: test lint

.PHONY: test
test:
	kcov \
		--clean \
		--include-path=./terminator/src/,./tmux/src/ \
		--include-pattern=.sh \
		--exclude-pattern=/test/,/coverage/,/report/ \
		--path-strip-level=1 \
		--bash-method=DEBUG \
		--bash-parser="$(BASH_PATH)" \
		--bash-parse-files-in-dir=. \
		--configure=command-name="$(TEST_COMMAND)" \
		coverage \
		$(TEST_COMMAND)

.PHONY: lint
lint:
	shellcheck $$(git ls-files -- $(LINTED_FILES))

.PHONY: linted-files
linted-files:
	git ls-files -- $(LINTED_FILES)

.PHONY: linted-source-files
linted-source-files:
	git ls-files -- $(LINTED_SOURCE_FILES)

.PHONY: linted-test-files
linted-test-files:
	git ls-files -- $(LINTED_TEST_FILES)

################################################################################
# Docker targets and config
################################################################################

FORCE ?= false

DOCKER_USER := kyle-reese
DOCKER_GROUP := skynet-resistance
DOCKER_WORKDIR := /opt

DOCKER_HUB_USER := rbuchss
DOCKER_BUILD_TARGET := terminator-tester
DOCKER_IMAGE_NAME := $(DOCKER_HUB_USER)/$(DOCKER_BUILD_TARGET)
DOCKER_BUILDER_TARGET := terminator-tester-builder
DOCKER_BUILDER_IMAGE_NAME := $(DOCKER_HUB_USER)/$(DOCKER_BUILDER_TARGET)

DOCKER_IMAGE_BASH_PATH := /usr/local/bin/bash

DOCKER_BUILD_FLAGS := \
  --target "$(DOCKER_BUILD_TARGET)" \
  --tag "$(DOCKER_IMAGE_NAME)" \
  --build-arg BUILDER_IMAGE_NAME=$(DOCKER_BUILDER_IMAGE_NAME) \
  --build-arg USER=$(DOCKER_USER) \
  --build-arg GROUP=$(DOCKER_GROUP) \
  --build-arg WORKDIR=$(DOCKER_WORKDIR)

DOCKER_BUILDER_FLAGS := \
  --target "$(DOCKER_BUILDER_TARGET)" \
  --tag "$(DOCKER_BUILDER_IMAGE_NAME)" \
  --build-arg WORKDIR=$(DOCKER_WORKDIR)

ifeq ($(FORCE),true)
DOCKER_BUILD_FLAGS += --no-cache
DOCKER_BUILDER_FLAGS += --no-cache
endif

DOCKER_RUN_FLAGS := \
  -it \
  --rm \
  --cap-drop all \
  --security-opt=no-new-privileges \
  "$(DOCKER_IMAGE_NAME)"

DOCKER_RUN_BUILDER_FLAGS := \
  -it \
  --rm \
  "$(DOCKER_BUILDER_IMAGE_NAME)"

.PHONY: docker-guards
docker-guards: docker-tester-build
	@$(MAKE) --no-print-directory docker-tester-run

.PHONY: docker-all-build
docker-all-build: docker-builder-build docker-tester-build

.PHONY: docker-all-run
docker-all-run: docker-all-build
	@$(MAKE) --no-print-directory docker-tester-run

.PHONY: docker-all-clean
docker-all-clean: docker-tester-clean docker-builder-clean

.PHONY: docker-tester-build
docker-tester-build:
	docker build . $(DOCKER_BUILD_FLAGS)

.PHONY: docker-tester-run
docker-tester-run:
	docker run $(DOCKER_RUN_FLAGS)

.PHONY: docker-tester-debug
docker-tester-debug:
	docker run $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE_BASH_PATH)

.PHONY: docker-tester-clean
docker-tester-clean:
	@if docker image inspect "$(DOCKER_IMAGE_NAME)" >/dev/null 2>&1; then \
		docker image remove "$(DOCKER_IMAGE_NAME)"; \
	else \
		echo "Skipping: No such image: $(DOCKER_IMAGE_NAME)"; \
	fi

.PHONY: docker-builder-build
docker-builder-build:
	docker build ./docker $(DOCKER_BUILDER_FLAGS)

.PHONY: docker-builder-push
docker-builder-push:
	docker push $(DOCKER_BUILDER_IMAGE_NAME)

.PHONY: docker-builder-debug
docker-builder-debug:
	docker run $(DOCKER_RUN_BUILDER_FLAGS) $(DOCKER_IMAGE_BASH_PATH)

.PHONY: docker-builder-clean
docker-builder-clean:
	@if docker image inspect "$(DOCKER_BUILDER_IMAGE_NAME)" >/dev/null 2>&1; then \
		docker image remove "$(DOCKER_BUILDER_IMAGE_NAME)"; \
	else \
		echo "Skipping: No such image: $(DOCKER_BUILDER_IMAGE_NAME)"; \
	fi
