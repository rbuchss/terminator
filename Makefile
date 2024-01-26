################################################################################
# Shared targets and config
################################################################################

BASH_PATH ?= /bin/bash
PWD ?= .
TEST_DIRS := terminator/test/ tmux/test/

LINTED_SOURCE_FILES := \
  ':(top,attr:category=source language=bash)'

LINTED_TEST_FILES := \
  ':(top,attr:category=test language=bash)' \
  ':(top,attr:category=test language=bats)'

LINTED_FILES := $(LINTED_SOURCE_FILES) $(LINTED_TEST_FILES)

# NOTE: Looks like we cannot use --pretty in github-action runners since they cause the following error:
#   /github/workspace/vendor/test/bats/bats-core/bin/bats --setup-suite-file ./test/test_suite.bash --pretty --recursive terminator/test/ tmux/test/
#   tput: No value for $TERM and no -T specified
#   /github/workspace/vendor/test/bats/bats-core/lib/bats-core/validator.bash: line 8: printf: write error: Broken pipe
# This likely due to the runner terminal settings or lack thereof - re the $TERM -T part
TEST_COMMAND_FLAGS := \
  --setup-suite-file ./test/test_suite.bash \
  --recursive

# Note this does not appear to fix the kcov issue fully
ifneq ($(TERM),)
TEST_COMMAND_FLAGS += --pretty
endif

TEST_COMMAND := $(PWD)/vendor/test/bats/bats-core/bin/bats \
  $(TEST_COMMAND_FLAGS) \
  $(TEST_DIRS)

.DEFAULT_GOAL := guards
.PHONY: guards
guards: test lint

# NOTE: For some reason kcov does not work under github-action runners
# TODO make this work - for now just skiping coverage in github-actions
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
		-- \
		$(TEST_COMMAND)

.PHONY: test-without-coverage
test-without-coverage:
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

DOCKER_IMAGE_BASH_VERSION := 3.2.57
DOCKER_IMAGE_BASH_PATH := /usr/local/bin/bash
DOCKER_IMAGE_KCOV_VERSION := v42

DOCKER_USER := kyle-reese
DOCKER_GROUP := skynet-resistance
DOCKER_WORKDIR := /opt

DOCKER_HUB_USER := rbuchss
DOCKER_TESTER_BUILD_TARGET := terminator-tester-local
DOCKER_TESTER_IMAGE_NAME := $(DOCKER_HUB_USER)/$(DOCKER_TESTER_BUILD_TARGET)
DOCKER_BUILDER_BUILD_TARGET := terminator-tester-builder
DOCKER_BUILDER_IMAGE_NAME := $(DOCKER_HUB_USER)/$(DOCKER_BUILDER_BUILD_TARGET)

DOCKER_TESTER_BUILD_FLAGS := \
  --target "$(DOCKER_TESTER_BUILD_TARGET)" \
  --tag "$(DOCKER_TESTER_IMAGE_NAME)" \
  --build-arg BUILDER_IMAGE_NAME=$(DOCKER_BUILDER_IMAGE_NAME) \
  --build-arg USER=$(DOCKER_USER) \
  --build-arg GROUP=$(DOCKER_GROUP) \
  --build-arg WORKDIR=$(DOCKER_WORKDIR)

DOCKER_BUILDER_BUILD_FLAGS := \
  --target "$(DOCKER_BUILDER_BUILD_TARGET)" \
  --tag "$(DOCKER_BUILDER_IMAGE_NAME)" \
  --build-arg IMAGE_BASH_VERSION=$(DOCKER_IMAGE_BASH_VERSION) \
  --build-arg IMAGE_BASH_PATH=$(DOCKER_IMAGE_BASH_PATH) \
  --build-arg IMAGE_KCOV_VERSION=$(DOCKER_IMAGE_KCOV_VERSION)

ifeq ($(FORCE),true)
DOCKER_TESTER_BUILD_FLAGS += --no-cache
DOCKER_BUILDER_BUILD_FLAGS += --no-cache
endif

DOCKER_TESTER_RUN_FLAGS := \
  -it \
  --rm \
  --cap-drop all \
  --security-opt=no-new-privileges \
  "$(DOCKER_TESTER_IMAGE_NAME)"

DOCKER_BUILDER_RUN_FLAGS := \
  -it \
  --rm \
  "$(DOCKER_BUILDER_IMAGE_NAME)"

.PHONY: docker-clean
docker-clean: docker-tester-clean docker-builder-clean

.PHONY: docker-tester-build
docker-tester-build: docker-builder-build
	docker build . $(DOCKER_TESTER_BUILD_FLAGS)

.PHONY: docker-tester-run
docker-tester-run: docker-tester-build
	docker run $(DOCKER_TESTER_RUN_FLAGS)

.PHONY: docker-tester-debug
docker-tester-debug:
	docker run $(DOCKER_TESTER_RUN_FLAGS) $(DOCKER_IMAGE_BASH_PATH)

.PHONY: docker-tester-clean
docker-tester-clean:
	@if docker image inspect "$(DOCKER_TESTER_IMAGE_NAME)" >/dev/null 2>&1; then \
		docker image remove "$(DOCKER_TESTER_IMAGE_NAME)"; \
	else \
		echo "Skipping: No such image: $(DOCKER_TESTER_IMAGE_NAME)"; \
	fi

.PHONY: docker-builder-build
docker-builder-build:
	docker build $(DOCKER_BUILDER_BUILD_FLAGS) ./test/test_builder

.PHONY: docker-builder-build-and-push
docker-builder-build-and-push:
	docker buildx build $(DOCKER_BUILDER_BUILD_FLAGS) --platform linux/amd64,linux/arm64 --push ./test/test_builder

.PHONY: docker-builder-debug
docker-builder-debug:
	docker run $(DOCKER_BUILDER_RUN_FLAGS) $(DOCKER_IMAGE_BASH_PATH)

.PHONY: docker-builder-clean
docker-builder-clean:
	@if docker image inspect "$(DOCKER_BUILDER_IMAGE_NAME)" >/dev/null 2>&1; then \
		docker image remove "$(DOCKER_BUILDER_IMAGE_NAME)"; \
	else \
		echo "Skipping: No such image: $(DOCKER_BUILDER_IMAGE_NAME)"; \
	fi

.PHONY: act-test
act-test:
	act --container-architecture linux/amd64 workflow_dispatch
