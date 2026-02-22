THIS_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

include $(THIS_DIR)/vendor/container-build-tools/modules.mk

.DEFAULT_GOAL := guards

################################################################################
# Platform defaults
################################################################################

ifeq ($(OS),Windows_NT)
  SHELL := pwsh.exe
  THIS_DIR := $(subst /,\,$(THIS_DIR))
else
  SHELL := /bin/bash
endif

################################################################################
# Docker defaults
################################################################################

# The builder base image (FROM ${BUILDER_IMAGE_NAME} in Dockerfile) is resolved
# by Docker automatically — pulled from registry if not available locally.
# To build the builder locally instead: make -C test/test_builder docker-build
DOCKER_IMAGE_NAME := rbuchss/terminator-tester-local
DOCKER_BUILD_TARGET := terminator-tester-local
DOCKER_IMAGE_BASH_PATH := /usr/local/bin/bash

DOCKER_USER := kyle-reese
DOCKER_GROUP := skynet-resistance
DOCKER_WORKDIR := /cyberdyne

DOCKER_BUILD_FLAGS := \
  --build-arg USER=$(DOCKER_USER) \
  --build-arg GROUP=$(DOCKER_GROUP) \
  --build-arg WORKDIR=$(DOCKER_WORKDIR)

DOCKER_RUN_FLAGS := \
  -it \
  --rm \
  --cap-drop all \
  --security-opt=no-new-privileges

DOCKER_DEBUG_CMD := $(DOCKER_IMAGE_BASH_PATH)

################################################################################
# Docker Compose macros
################################################################################

# Compose runner
# Usage: $(call compose-run,COMMAND)
#
# :param $(1): Command to run inside the container
define compose-run
	docker compose run --rm tester $(DOCKER_IMAGE_BASH_PATH) -c \
		'git config --global --add safe.directory /workspace && $(1)'
endef

# Compose make runner
# Usage: $(call compose-make-test,TARGET)
#
# :param $(1): Make target to run inside the container
#
# Passes through TEST_DIRS and FILTER_TAGS when set on the command line.
define compose-make-test
	$(call compose-run,make $(1) TEST_DIRS=$(TEST_DIRS)$(if $(FILTER_TAGS), FILTER_TAGS=$(FILTER_TAGS)))
endef

################################################################################
# Docker Compose targets
################################################################################

.PHONY: compose-test
compose-test:
	$(call compose-make-test,test)

.PHONY: compose-test-with-coverage
compose-test-with-coverage:
	$(call compose-make-test,test-with-coverage)

.PHONY: compose-debug
compose-debug:
	$(call compose-run,exec $(DOCKER_IMAGE_BASH_PATH))

################################################################################
# GitHub Actions targets
################################################################################

# Useful to test out github-action workflow with linux/amd64 platform.
# Since we are doing cross platform builds we need to ensure linux/amd64 is stable.
# Testing locally with only linux/arm64 can pass while linux/amd64 can be unstable
# which means that github-action workflows may not run ok due to platform specific issues.
# WARNING: This does not work with M2 Max chipset which causes a segfault - works ok on M1 Max.
.PHONY: act-test
act-test:
	act --container-architecture linux/amd64 workflow_dispatch

################################################################################
# Test defaults
################################################################################

TEST_DIRS ?= test/

ifeq ($(OS),Windows_NT)
  PATH := $(PATH);$(THIS_DIR)\test\bin
else
  PATH := $(PATH):$(THIS_DIR)/test/bin
endif

################################################################################
# Test macros
################################################################################

# Bats test command builder
# Usage: $(call test-command)
#
# Evaluated at expansion time — supports runtime overrides.
#
# NOTE: We cannot use --pretty in github-action runners since they cause the following error:
#   /github/workspace/vendor/test/bats/bats-core/bin/bats --setup-suite-file ./test/test_suite.bash --pretty --recursive test/
#   tput: No value for $TERM and no -T specified
#   /github/workspace/vendor/test/bats/bats-core/lib/bats-core/validator.bash: line 8: printf: write error: Broken pipe
# This is due to the runner terminal settings or lack thereof - re the $TERM -T part.
# So we only enable --pretty if the TERM env var is set.
#
# Override examples:
#   make test TEST_DIRS=test/logger.bats
#   make test FILTER_TAGS=terminator::logger
define test-command
$(THIS_DIR)/vendor/test/bats/bats-core/bin/bats \
  --setup-suite-file ./test/test_suite.bash \
  --recursive \
  $(if $(TERM),--pretty) \
  $(if $(FILTER_TAGS),--filter-tags $(FILTER_TAGS)) \
  $(TEST_DIRS)
endef

################################################################################
# Test targets
################################################################################

.PHONY: guards
guards: test-with-coverage lint

.PHONY: test
test:
	$(call run-in-bash,$(call test-command))

################################################################################
# Coverage defaults
################################################################################

COVERAGE_BASH_PARSER ?= /bin/bash
COVERAGE_REPORT_BASE_SHA ?= origin/main
COVERAGE_REPORT_HEAD_SHA ?= HEAD
COVERAGE_REPORT_OUTPUT ?= /dev/stdout

################################################################################
# Coverage targets
################################################################################

# Wraps bats in kcov for code coverage instrumentation.
# NOTE: github-action runners use linux/amd64.
# So the builder image needs to also be build using this platform using buildx.
.PHONY: test-with-coverage
test-with-coverage:
	$(call run-in-bash,kcov \
		--clean \
		--include-path=./terminator/src/ \
		--include-pattern=.sh \
		--exclude-pattern=/test/$(COMMA)/coverage/$(COMMA)/report/ \
		--bash-method=DEBUG \
		--bash-parser="$(COVERAGE_BASH_PARSER)" \
		--bash-parse-files-in-dir=. \
		--configure=command-name="$(call test-command)" \
		coverage \
		-- \
		$(call test-command))
	@$(MAKE) --no-print-directory coverage-pr-report

.PHONY: coverage-pr-report
coverage-pr-report:
	[[ -n "$(COVERAGE_REPORT_BASE_SHA)" && -n "$(COVERAGE_REPORT_HEAD_SHA)" ]] \
		&& $(THIS_DIR)/test/test_coverage/generate_report.sh \
			pull-request \
			"$(COVERAGE_REPORT_BASE_SHA)" \
			"$(COVERAGE_REPORT_HEAD_SHA)" \
			"$(COVERAGE_REPORT_OUTPUT)"

.PHONY: coverage-summary
coverage-summary:
	@$(THIS_DIR)/test/test_coverage/generate_report.sh summary

.PHONY: coverage-files
coverage-files:
	@$(THIS_DIR)/test/test_coverage/generate_report.sh files

################################################################################
# Lint defaults
################################################################################

LINTED_SOURCE_FILES := \
  ':(top,attr:category=source language=bash)'

LINTED_TEST_FILES := \
  ':(top,attr:category=test language=bash)' \
  ':(top,attr:category=test language=bats)'

LINTED_FILES := $(LINTED_SOURCE_FILES) $(LINTED_TEST_FILES)

################################################################################
# Lint targets
################################################################################

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
# Function exports
################################################################################

.PHONY: function-exports
function-exports:
	@if ! $(THIS_DIR)/terminator/tools/__module__/generate_function_exports.sh false; then \
		printf '\n> Add function exports to files? [y/N] '; \
		read reply; \
		if [[ "$${reply:-N}" == 'y' ]]; then \
			$(THIS_DIR)/terminator/tools/__module__/generate_function_exports.sh true; \
		else \
			echo 'Answered no - Skipping apply step'; \
		fi \
	else \
		echo 'No missing function exports found!'; \
	fi
