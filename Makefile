################################################################################
# Shared targets and config
################################################################################

BASH_PATH ?= /bin/bash
PWD ?= .

COVERAGE_REPORT_BASE_SHA ?= origin/main
COVERAGE_REPORT_HEAD_SHA ?= HEAD
COVERAGE_REPORT_OUTPUT ?= /dev/stdout

TEST_DIRS := terminator/test/ tmux/test/

LINTED_SOURCE_FILES := \
  ':(top,attr:category=source language=bash)'

LINTED_TEST_FILES := \
  ':(top,attr:category=test language=bash)' \
  ':(top,attr:category=test language=bats)'

LINTED_FILES := $(LINTED_SOURCE_FILES) $(LINTED_TEST_FILES)

TEST_COMMAND_FLAGS := \
  --setup-suite-file ./test/test_suite.bash \
  --recursive

# NOTE: We cannot use --pretty in github-action runners since they cause the following error:
#   /github/workspace/vendor/test/bats/bats-core/bin/bats --setup-suite-file ./test/test_suite.bash --pretty --recursive terminator/test/ tmux/test/
#   tput: No value for $TERM and no -T specified
#   /github/workspace/vendor/test/bats/bats-core/lib/bats-core/validator.bash: line 8: printf: write error: Broken pipe
# This is due to the runner terminal settings or lack thereof - re the $TERM -T part.
# So we only enable --pretty if the TERM env var is set.
ifneq ($(TERM),)
TEST_COMMAND_FLAGS += --pretty
endif

# TODO convert PWD to THIS_DIR
TEST_COMMAND := $(PWD)/vendor/test/bats/bats-core/bin/bats \
  $(TEST_COMMAND_FLAGS) \
  $(TEST_DIRS)

.DEFAULT_GOAL := guards
.PHONY: guards
guards: test-with-coverage lint

# NOTE: github-action runners use linux/amd64.
# So the builder image needs to also be build using this platform using buildx.
.PHONY: test
test:
	$(TEST_COMMAND)

# TODO convert PWD to THIS_DIR
.PHONY: test-with-coverage
test-with-coverage:
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
	[[ -n "$(COVERAGE_REPORT_BASE_SHA)" && -n "$(COVERAGE_REPORT_HEAD_SHA)" ]] \
		&& $(PWD)/test/test_coverage/generate_report.sh \
			"$(COVERAGE_REPORT_BASE_SHA)" \
			"$(COVERAGE_REPORT_HEAD_SHA)" \
			"$(COVERAGE_REPORT_OUTPUT)"

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
USE_PREBUILT_BUILDER ?= true

DOCKER_IMAGE_BASH_VERSION := 3.2.57
DOCKER_IMAGE_BASH_PATH := /usr/local/bin/bash
DOCKER_IMAGE_KCOV_VERSION := v42

DOCKER_USER := kyle-reese
DOCKER_GROUP := skynet-resistance
DOCKER_WORKDIR := /cyberdyne
DOCKER_BUILDX_NAME := doctor-miles-bennett-dyson
DOCKER_BUILDX_PLATFORMS := linux/amd64,linux/arm64

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

DOCKER_BUILDER_BUILDX_FLAGS := \
  $(DOCKER_BUILDER_BUILD_FLAGS) \
  --platform $(DOCKER_BUILDX_PLATFORMS) \
  --builder $(DOCKER_BUILDX_NAME)

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
docker-clean: docker-tester-clean docker-builder-clean docker-image-prune

.PHONY: docker-tester-build
docker-tester-build: docker-builder-get
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
		echo "Skipping - $(DOCKER_TESTER_IMAGE_NAME): No such image"; \
	fi

ifeq ($(USE_PREBUILT_BUILDER),true)
.PHONY: docker-builder-get
docker-builder-get: docker-builder-pull
else
.PHONY: docker-builder-get
docker-builder-get: docker-builder-buildx-build
endif

.PHONY: docker-builder-debug
docker-builder-debug:
	docker run $(DOCKER_BUILDER_RUN_FLAGS) $(DOCKER_IMAGE_BASH_PATH)

.PHONY: docker-builder-clean
docker-builder-clean:
	@if docker image inspect "$(DOCKER_BUILDER_IMAGE_NAME)" >/dev/null 2>&1; then \
		docker image remove "$(DOCKER_BUILDER_IMAGE_NAME)"; \
	else \
		echo "Skipping - $(DOCKER_BUILDER_IMAGE_NAME): No such image"; \
	fi

# Useful to test out github-action workflow with linux/amd64 platform.
# Since we are doing cross platform builds we need to ensure linux/amd64 is stable.
# Testing locally with only linux/arm64 can pass while linux/amd64 can be unstable
# which means that github-action workflows may not run ok due to platform specific issues.
# WARNING: This does not work with M2 Max chipset which causes a segfault - works ok on M1 Max.
.PHONY: act-test
act-test:
	act --container-architecture linux/amd64 workflow_dispatch

.PHONY: docker-builder-pull
docker-builder-pull:
	docker image pull $(DOCKER_BUILDER_IMAGE_NAME)

# Using QEMU to do cross platform builds
# https://docs.docker.com/build/building/multi-platform/#qemu
.PHONY: docker-builder-buildx-install
docker-builder-buildx-install:
	docker run --privileged --rm tonistiigi/binfmt --install all

# Creating a builder for cross platform builds
# https://docs.docker.com/build/building/multi-platform/#qemu
.PHONY: docker-builder-buildx-bootstrap
docker-builder-buildx-bootstrap: docker-builder-buildx-install
	@if docker buildx inspect "$(DOCKER_BUILDX_NAME)" >/dev/null 2>&1; then \
		echo "Skipping - $(DOCKER_BUILDX_NAME): buildx container is already running"; \
	else \
		docker buildx create --bootstrap --name $(DOCKER_BUILDX_NAME); \
	fi

.PHONY: docker-builder-buildx-build
docker-builder-buildx-build: docker-builder-buildx-bootstrap
	docker buildx build $(DOCKER_BUILDER_BUILDX_FLAGS) ./test/test_builder

.PHONY: docker-builder-buildx-push
docker-builder-buildx-push: docker-builder-buildx-bootstrap
	docker buildx build --push $(DOCKER_BUILDER_BUILDX_FLAGS) ./test/test_builder

.PHONY: docker-builder-buildx-clean
docker-builder-buildx-clean:
	@if docker buildx inspect "$(DOCKER_BUILDX_NAME)" >/dev/null 2>&1; then \
		docker buildx rm $(DOCKER_BUILDX_NAME); \
	else \
		echo "Skipping - $(DOCKER_BUILDX_NAME): buildx container not found"; \
	fi
	@for image in moby/buildkit:buildx-stable-1 tonistiigi/binfmt; do \
	if docker image inspect "$${image}" >/dev/null 2>&1; then \
		docker image remove "$${image}"; \
	else \
		echo "Skipping - $${image}: No such image"; \
	fi; \
	done

.PHONY: docker-image-prune
docker-image-prune:
	docker image prune
