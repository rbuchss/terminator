################################################################################
# Docker common defaults
################################################################################

DOCKER_TARGET_NAMESPACE ?= $(CONTAINER_BUILD_TOOLS_NAMESPACE)
DOCKER ?= docker

################################################################################
# Docker build defaults
################################################################################

# Build strategy: 'build' (default) or 'buildx' for multi architecture builds
DOCKER_BUILD_STRATEGY ?= build

# Use DOCKER_IMAGE_NAME envvar to specify docker image with tags
# Use ARGS to pass arguments
DOCKER_BUILD_PATH ?= .

# Do not set any default value for DOCKER_BUILD_FLAGS, as it is hard to override with nothing
DOCKER_FILE ?=
DOCKER_BUILD_TARGET ?=
DOCKER_BUILD_PLATFORM ?=

################################################################################
# Docker buildx defaults
################################################################################

DOCKER_BUILDX_BUILDER_NAME ?= buildx-builder

################################################################################
# Docker run defaults
################################################################################

DOCKER_RUN_FLAGS ?= -it --rm
DOCKER_RUN_PLATFORM ?=
DOCKER_DEBUG_CMD ?= sh

################################################################################
# Docker pull/push defaults
################################################################################

DOCKER_PULL_FLAGS ?=
DOCKER_PULL_PLATFORM ?=
DOCKER_PUSH_FLAGS ?=

################################################################################
# Docker tag defaults
################################################################################

DOCKER_TAG_FLAGS ?=

################################################################################
# Docker clean defaults
################################################################################

# Set to 'true' to enable --all flag (removes ALL unused resources, not just dangling)
DOCKER_CLEAN_ALL ?= false

# Set to 'true' to enable --force flag (skip confirmation prompts during cleanup)
DOCKER_CLEAN_FORCE ?= false

################################################################################
# Docker common macros
################################################################################

# Helper: Check if a flag is present in given flags variable
# Usage: $(call has-flag,FLAGS_VAR,--flag)
#
# :param $(1): The flags variable to search in (e.g., $(DOCKER_BUILD_FLAGS))
# :param $(2): The flag to search for (e.g., --target, --platform)
# :return: non-empty if flag is found, empty otherwise
define has-flag
$(findstring $(2),$(1))
endef

# Helper: Warn if both a variable and its flag are specified in flags
# Usage: $(call warn-if-has-flag-collision,VARIABLE_VALUE,--flag,VARIABLE_NAME,FLAGS_VAR,FLAGS_VAR_NAME)
#
# :param $(1): The value of the variable to check (e.g., $(DOCKER_BUILD_TARGET))
# :param $(2): The flag to check for collision (e.g., --target)
# :param $(3): The variable name for the warning message (e.g., DOCKER_BUILD_TARGET)
# :param $(4): The flags variable to check (e.g., $(DOCKER_BUILD_FLAGS))
# :param $(5): The flags variable name for the warning message (e.g., DOCKER_BUILD_FLAGS)
define warn-if-has-flag-collision
$(if $(and $(1),$(call has-flag,$(4),$(2))),\
	$(warning WARNING: Both $(3) and $(2) in $(5) specified. Using $(5) version.))
endef

# Helper: Add flag to command if variable is set and flag not already present
# Usage: $(call add-flag-if-not-present,FLAGS_VAR,VARIABLE_VALUE,--flag)
#
# :param $(1): The flags variable to check (e.g., $(DOCKER_BUILD_FLAGS))
# :param $(2): The value to use with the flag (e.g., $(DOCKER_BUILD_TARGET))
# :param $(3): The flag to conditionally add (e.g., --target)
# :return: "--flag VALUE" if variable is set and flag not present, empty otherwise
define add-flag-if-not-present
$(if $(2),$(if $(call has-flag,$(1),$(3)),,$(3) $(2)))
endef

################################################################################
# Docker build macros
################################################################################

# Helper: Check if a flag is present in DOCKER_BUILD_FLAGS
# Usage: $(call has-build-flag,--flag)
#
# :param $(1): The flag to search for (e.g., --target, --platform)
# :return: non-empty if flag is found, empty otherwise
define has-build-flag
$(call has-flag,$(DOCKER_BUILD_FLAGS),$(1))
endef

# Helper: Warn if both a variable and its flag are specified in DOCKER_BUILD_FLAGS
# Usage: $(call warn-if-has-build-flag-collision,VARIABLE_VALUE,--flag,VARIABLE_NAME)
#
# :param $(1): The value of the variable to check (e.g., $(DOCKER_BUILD_TARGET))
# :param $(2): The flag to check for collision (e.g., --target)
# :param $(3): The variable name for the warning message (e.g., DOCKER_BUILD_TARGET)
define warn-if-has-build-flag-collision
$(call warn-if-has-flag-collision,$(1),$(2),$(3),$(DOCKER_BUILD_FLAGS),DOCKER_BUILD_FLAGS)
endef

# Helper: Add flag to build command if variable is set and flag not already present
# Usage: $(call add-build-flag-if-not-present,VARIABLE_VALUE,--flag)
#
# :param $(1): The value to use with the flag (e.g., $(DOCKER_BUILD_TARGET))
# :param $(2): The flag to conditionally add (e.g., --target)
# :return: "--flag VALUE" if variable is set and flag not present, empty otherwise
define add-build-flag-if-not-present
$(call add-flag-if-not-present,$(DOCKER_BUILD_FLAGS),$(1),$(2))
endef

# Generic docker build implementation
# Usage: $(call docker-build-generic-impl,COMMAND,EXTRA_FLAGS,ADDITIONAL_FLAGS)
#
# :param $(1): Build command (e.g., "build" or "buildx build")
# :param $(2): Label for output (e.g., "opts" or "buildx")
# :param $(3): Extra flags to insert before standard flags (e.g., "--builder NAME")
# :param $(4): Additional flags to pass through (e.g., "--load", "--push", "--no-cache")
define docker-build-generic-impl
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_IMAGE_NAME)
	$(call assert-set,DOCKER_BUILD_PATH)
	$(call warn-if-has-build-flag-collision,$(DOCKER_BUILD_TARGET),--target,DOCKER_BUILD_TARGET)
	$(call warn-if-has-build-flag-collision,$(DOCKER_BUILD_PLATFORM),--platform,DOCKER_BUILD_PLATFORM)
	$(call warn-if-has-build-flag-collision,$(DOCKER_FILE),--file,DOCKER_FILE)
	@BUILD_ARGS=`for arg in $$ARGS; do \
		printf -- '--build-arg %s=%s ' "$$arg" "$${!arg}"; \
	done`; \
	echo "Building $(DOCKER_IMAGE_NAME)$(if $(DOCKER_FILE), from $(DOCKER_FILE)) with $(2) [$(DOCKER_BUILD_FLAGS)$${BUILD_ARGS:+ $${BUILD_ARGS}}]..."; \
	$(call if-verbose,set -x;) \
	"$(DOCKER)" $(1) \
		$(3) \
		$(call if-verbose,--debug,1) \
		$(DOCKER_BUILD_FLAGS) \
		$(call add-build-flag-if-not-present,$(DOCKER_BUILD_TARGET),--target) \
		$(call add-build-flag-if-not-present,$(DOCKER_BUILD_PLATFORM),--platform) \
		$(call add-build-flag-if-not-present,$(DOCKER_FILE),--file) \
		$(4) \
		$$BUILD_ARGS \
		--tag $(DOCKER_IMAGE_NAME) \
		$(DOCKER_BUILD_PATH)
endef

# Shared docker build implementation
# Usage: $(call docker-build-impl,ADDITIONAL_FLAGS)
#
# :param $(1): Additional flags to pass through (e.g., "--no-cache")
define docker-build-impl
	$(call docker-build-generic-impl,build,opts,,$(1))
endef

# Shared docker buildx implementation
# Usage: $(call docker-buildx-impl,ADDITIONAL_FLAGS)
#
# :param $(1): Additional flags to pass through (e.g., "--load", "--no-cache")
define docker-buildx-impl
	$(call docker-build-generic-impl,buildx build,buildx,--builder $(DOCKER_BUILDX_BUILDER_NAME),$(1))
endef

################################################################################
# Docker run macros
################################################################################

# Helper: Check if a flag is present in DOCKER_RUN_FLAGS
# Usage: $(call has-run-flag,--flag)
#
# :param $(1): The flag to search for (e.g., --platform)
# :return: non-empty if flag is found, empty otherwise
define has-run-flag
$(call has-flag,$(DOCKER_RUN_FLAGS),$(1))
endef

# Helper: Warn if both a variable and its flag are specified in DOCKER_RUN_FLAGS
# Usage: $(call warn-if-has-run-flag-collision,VARIABLE_VALUE,--flag,VARIABLE_NAME)
#
# :param $(1): The value of the variable to check (e.g., $(DOCKER_RUN_PLATFORM))
# :param $(2): The flag to check for collision (e.g., --platform)
# :param $(3): The variable name for the warning message (e.g., DOCKER_RUN_PLATFORM)
define warn-if-has-run-flag-collision
$(call warn-if-has-flag-collision,$(1),$(2),$(3),$(DOCKER_RUN_FLAGS),DOCKER_RUN_FLAGS)
endef

# Helper: Add flag to run command if variable is set and flag not already present
# Usage: $(call add-run-flag-if-not-present,VARIABLE_VALUE,--flag)
#
# :param $(1): The value to use with the flag (e.g., $(DOCKER_RUN_PLATFORM))
# :param $(2): The flag to conditionally add (e.g., --platform)
# :return: "--flag VALUE" if variable is set and flag not present, empty otherwise
define add-run-flag-if-not-present
$(call add-flag-if-not-present,$(DOCKER_RUN_FLAGS),$(1),$(2))
endef

# Shared docker run implementation
# Usage: $(call docker-run-impl,ADDITIONAL_ARGS)
#
# :param $(1): Additional arguments to pass to docker run (e.g., command to execute)
define docker-run-impl
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_IMAGE_NAME)
	$(call warn-if-has-run-flag-collision,$(DOCKER_RUN_PLATFORM),--platform,DOCKER_RUN_PLATFORM)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) run \
		$(DOCKER_RUN_FLAGS) \
		$(call add-run-flag-if-not-present,$(DOCKER_RUN_PLATFORM),--platform) \
		$(DOCKER_IMAGE_NAME) \
		$(1)
endef

################################################################################
# Docker pull macros
################################################################################

# Helper: Check if a flag is present in DOCKER_PULL_FLAGS
# Usage: $(call has-pull-flag,--flag)
#
# :param $(1): The flag to search for (e.g., --platform)
# :return: non-empty if flag is found, empty otherwise
define has-pull-flag
$(call has-flag,$(DOCKER_PULL_FLAGS),$(1))
endef

# Helper: Warn if both a variable and its flag are specified in DOCKER_PULL_FLAGS
# Usage: $(call warn-if-has-pull-flag-collision,VARIABLE_VALUE,--flag,VARIABLE_NAME)
#
# :param $(1): The value of the variable to check (e.g., $(DOCKER_PULL_PLATFORM))
# :param $(2): The flag to check for collision (e.g., --platform)
# :param $(3): The variable name for the warning message (e.g., DOCKER_PULL_PLATFORM)
define warn-if-has-pull-flag-collision
$(call warn-if-has-flag-collision,$(1),$(2),$(3),$(DOCKER_PULL_FLAGS),DOCKER_PULL_FLAGS)
endef

# Helper: Add flag to pull command if variable is set and flag not already present
# Usage: $(call add-pull-flag-if-not-present,VARIABLE_VALUE,--flag)
#
# :param $(1): The value to use with the flag (e.g., $(DOCKER_PULL_PLATFORM))
# :param $(2): The flag to conditionally add (e.g., --platform)
# :return: "--flag VALUE" if variable is set and flag not present, empty otherwise
define add-pull-flag-if-not-present
$(call add-flag-if-not-present,$(DOCKER_PULL_FLAGS),$(1),$(2))
endef

################################################################################
# Docker clean macros
################################################################################

# Helper: Get --all flag if DOCKER_CLEAN_ALL is true
# Usage: $(call get-clean-all-flag)
# :return: "--all" if DOCKER_CLEAN_ALL is true, empty otherwise
define get-clean-all-flag
$(if $(filter true,$(DOCKER_CLEAN_ALL)),--all)
endef

# Helper: Get --force flag if DOCKER_CLEAN_FORCE is true
# Usage: $(call get-clean-force-flag)
# :return: "--force" if DOCKER_CLEAN_FORCE is true, empty otherwise
define get-clean-force-flag
$(if $(filter true,$(DOCKER_CLEAN_FORCE)),--force)
endef

################################################################################
# Docker build targets
################################################################################

## Build docker image
## Uses DOCKER_BUILD_STRATEGY to choose between 'build' or 'buildx'
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-build
$(DOCKER_TARGET_NAMESPACE)docker-build:
	$(if $(filter buildx,$(DOCKER_BUILD_STRATEGY)),\
		@$(call if-verbose,set -x;)\
		"$(MAKE)" $(DOCKER_TARGET_NAMESPACE)docker-buildx-install DOCKER_BUILDX_BUILDER_NAME="$(DOCKER_BUILDX_BUILDER_NAME)")
	$(if $(filter buildx,$(DOCKER_BUILD_STRATEGY)),\
		$(call docker-buildx-impl,--load),\
		$(call docker-build-impl,))

## Build docker image with --no-cache flag
## Uses DOCKER_BUILD_STRATEGY to choose between 'build' or 'buildx'
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-build-clean
$(DOCKER_TARGET_NAMESPACE)docker-build-clean:
	$(if $(filter buildx,$(DOCKER_BUILD_STRATEGY)),\
		@$(call if-verbose,set -x;)\
		"$(MAKE)" $(DOCKER_TARGET_NAMESPACE)docker-buildx-install DOCKER_BUILDX_BUILDER_NAME="$(DOCKER_BUILDX_BUILDER_NAME)")
	$(if $(filter buildx,$(DOCKER_BUILD_STRATEGY)),\
		$(call docker-buildx-impl,--load --no-cache),\
		$(call docker-build-impl,--no-cache))

################################################################################
# Docker buildx targets
################################################################################

## Install QEMU and create buildx builder
## Sets up multi-platform build support using Docker Buildx
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-buildx-install
$(DOCKER_TARGET_NAMESPACE)docker-buildx-install:
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_BUILDX_BUILDER_NAME)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) run --privileged --rm tonistiigi/binfmt --install all
	@if "$(DOCKER)" buildx inspect "$(DOCKER_BUILDX_BUILDER_NAME)" >/dev/null 2>&1; then \
		echo "Buildx builder '$(DOCKER_BUILDX_BUILDER_NAME)' already exists"; \
	else \
		$(call if-verbose,set -x;) \
		"$(DOCKER)" $(call if-verbose,--debug,1) buildx create --bootstrap --name $(DOCKER_BUILDX_BUILDER_NAME); \
	fi

## Remove buildx builder and dependencies
## Cleans up buildx builder and associated images
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-buildx-remove
$(DOCKER_TARGET_NAMESPACE)docker-buildx-remove:
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_BUILDX_BUILDER_NAME)
	@if "$(DOCKER)" buildx inspect "$(DOCKER_BUILDX_BUILDER_NAME)" >/dev/null 2>&1; then \
		$(call if-verbose,set -x;) \
		"$(DOCKER)" $(call if-verbose,--debug,1) buildx rm $(DOCKER_BUILDX_BUILDER_NAME); \
	else \
		echo "Buildx builder '$(DOCKER_BUILDX_BUILDER_NAME)' not found"; \
	fi
	@for image in moby/buildkit:buildx-stable-1 tonistiigi/binfmt; do \
	if "$(DOCKER)" image inspect "$${image}" >/dev/null 2>&1; then \
		$(call if-verbose,set -x;) \
		"$(DOCKER)" $(call if-verbose,--debug,1) image remove "$${image}"; \
	else \
		echo "Skipping - $${image}: No such image"; \
	fi; \
	done

################################################################################
# Docker pull/push targets
################################################################################

## Pull docker image from registry
## Supports platform-specific pulls via DOCKER_PULL_PLATFORM
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-pull
$(DOCKER_TARGET_NAMESPACE)docker-pull:
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_IMAGE_NAME)
	$(call warn-if-has-pull-flag-collision,$(DOCKER_PULL_PLATFORM),--platform,DOCKER_PULL_PLATFORM)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) image pull \
		$(DOCKER_PULL_FLAGS) \
		$(call add-pull-flag-if-not-present,$(DOCKER_PULL_PLATFORM),--platform) \
		$(DOCKER_IMAGE_NAME)

## Push docker image to registry
## Works with any container registry (Docker Hub, GCR, Artifact Registry, ECR, GHCR, etc.)
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-push
$(DOCKER_TARGET_NAMESPACE)docker-push:
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_IMAGE_NAME)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) image push $(DOCKER_PUSH_FLAGS) $(DOCKER_IMAGE_NAME)

## Tag docker image with a new name
## Requires DOCKER_SOURCE_IMAGE_NAME and DOCKER_TARGET_IMAGE_NAME (or DOCKER_IMAGE_NAME)
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-tag
$(DOCKER_TARGET_NAMESPACE)docker-tag:
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_SOURCE_IMAGE_NAME)
	$(if $(or $(DOCKER_TARGET_IMAGE_NAME),$(DOCKER_IMAGE_NAME)),,\
		$(error DOCKER_TARGET_IMAGE_NAME or DOCKER_IMAGE_NAME must be set))
	@echo "Tagging $(DOCKER_SOURCE_IMAGE_NAME) as $(or $(DOCKER_TARGET_IMAGE_NAME),$(DOCKER_IMAGE_NAME))..."
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) tag $(DOCKER_TAG_FLAGS) \
		$(DOCKER_SOURCE_IMAGE_NAME) $(or $(DOCKER_TARGET_IMAGE_NAME),$(DOCKER_IMAGE_NAME))

################################################################################
# Docker run targets
################################################################################

## Run docker image
## Use DOCKER_RUN_FLAGS to customize container options
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-run
$(DOCKER_TARGET_NAMESPACE)docker-run:
	$(call docker-run-impl,)

## Run docker image with interactive shell for debugging
## Launches container with DOCKER_DEBUG_CMD (default: sh)
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-debug
$(DOCKER_TARGET_NAMESPACE)docker-debug:
	$(call assert-set,DOCKER_DEBUG_CMD)
	$(call docker-run-impl,$(DOCKER_DEBUG_CMD))

################################################################################
# Docker clean targets
################################################################################

## Remove specified image and prune all docker resources
## Use DOCKER_CLEAN_ALL=true to remove ALL unused resources (not just dangling)
## Use DOCKER_CLEAN_FORCE=true to skip all confirmation prompts
## Combines docker-remove-image with all prune operations for comprehensive cleanup
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-clean-all
$(DOCKER_TARGET_NAMESPACE)docker-clean-all: \
	$(DOCKER_TARGET_NAMESPACE)docker-remove-image \
	$(DOCKER_TARGET_NAMESPACE)docker-clean-images \
	$(DOCKER_TARGET_NAMESPACE)docker-clean-builder \
	$(DOCKER_TARGET_NAMESPACE)docker-clean-volumes \
	$(DOCKER_TARGET_NAMESPACE)docker-clean-networks \
	$(DOCKER_TARGET_NAMESPACE)docker-clean-containers

## Remove specified docker image from local system
## Safely skips if image doesn't exist
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-remove-image
$(DOCKER_TARGET_NAMESPACE)docker-remove-image:
	$(call assert-set,DOCKER)
	$(call assert-set,DOCKER_IMAGE_NAME)
	@if "$(DOCKER)" image inspect "$(DOCKER_IMAGE_NAME)" >/dev/null 2>&1; then \
		$(call if-verbose,set -x;) \
		"$(DOCKER)" $(call if-verbose,--debug,1) image remove "$(DOCKER_IMAGE_NAME)"; \
	else \
		echo "Skipping - $(DOCKER_IMAGE_NAME): No such image"; \
	fi

## Remove dangling images (or all unused images if DOCKER_CLEAN_ALL=true)
## Use DOCKER_CLEAN_ALL=true to remove ALL unused images, not just dangling ones
## Use DOCKER_CLEAN_FORCE=true to skip confirmation prompt
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-clean-images
$(DOCKER_TARGET_NAMESPACE)docker-clean-images:
	$(call assert-set,DOCKER)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) image prune $(call get-clean-all-flag) $(call get-clean-force-flag)

## Remove unused build cache from Docker buildx builder (or all cache if DOCKER_CLEAN_ALL=true)
## By default, targets 'buildx-builder'. Set DOCKER_BUILDX_BUILDER_NAME= (empty) for current builder
## Set DOCKER_BUILDX_BUILDER_NAME to target a specific builder (e.g., my-builder)
## Use DOCKER_CLEAN_ALL=true to remove ALL build cache, not just dangling cache
## Use DOCKER_CLEAN_FORCE=true to skip confirmation prompt
## Critical for freeing disk space when using buildx - can reclaim significant storage
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-clean-builder
$(DOCKER_TARGET_NAMESPACE)docker-clean-builder:
	$(call assert-set,DOCKER)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) buildx prune \
		$(if $(DOCKER_BUILDX_BUILDER_NAME),--builder $(DOCKER_BUILDX_BUILDER_NAME)) \
		$(call get-clean-all-flag) $(call get-clean-force-flag)

## Remove unused Docker volumes (or all anonymous volumes if DOCKER_CLEAN_ALL=true)
## Use DOCKER_CLEAN_ALL=true to remove all anonymous volumes, not just unused ones
## Use DOCKER_CLEAN_FORCE=true to skip confirmation prompt
## Frees disk space from volumes no longer attached to containers
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-clean-volumes
$(DOCKER_TARGET_NAMESPACE)docker-clean-volumes:
	$(call assert-set,DOCKER)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) volume prune $(call get-clean-all-flag) $(call get-clean-force-flag)

## Remove unused Docker networks
## Use DOCKER_CLEAN_FORCE=true to skip confirmation prompt
## Cleans up custom networks not used by any containers
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-clean-networks
$(DOCKER_TARGET_NAMESPACE)docker-clean-networks:
	$(call assert-set,DOCKER)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) network prune $(call get-clean-force-flag)

## Remove stopped containers
## Use DOCKER_CLEAN_FORCE=true to skip confirmation prompt
## Frees disk space from containers that have exited
.PHONY: $(DOCKER_TARGET_NAMESPACE)docker-clean-containers
$(DOCKER_TARGET_NAMESPACE)docker-clean-containers:
	$(call assert-set,DOCKER)
	@$(call if-verbose,set -x;) \
	"$(DOCKER)" $(call if-verbose,--debug,1) container prune $(call get-clean-force-flag)
