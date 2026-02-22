################################################################################
# Common defaults
################################################################################

VERBOSE ?= 0

# Literal comma for use inside $(call ...) where commas are argument separators
COMMA := ,

# Auto-detect color support: enabled if TERM is set and not "dumb"
# Can be overridden by setting HELP_COLOR_ENABLED=0 to disable colors
HELP_COLOR_ENABLED ?= $(shell [ -n "$$TERM" ] && [ "$$TERM" != "dumb" ] && echo 1 || echo 0)

################################################################################
# Common macros
################################################################################

# Ensures that a variable is defined and non-empty
# Usage: $(call assert-set,VARIABLE_NAME)
#
# :param $(1): The name of the variable to check
define assert-set
@$(if $($(1)),,$(error ERROR: $(1) not defined in $(@)))
endef

# Conditionally include content if VERBOSE is greater than threshold
# Usage: $(call if-verbose,CONTENT,THRESHOLD)
#
# :param $(1): The content to include if verbose (e.g., "set -x;")
# :param $(2): Optional verbosity threshold (defaults to 0)
define if-verbose
$(if $(shell [ $(VERBOSE) -gt $(or $(2),0) ] && echo 1),$(1))
endef

# Run a command in bash regardless of platform
# Usage: $(call run-in-bash,COMMAND)
#
# :param $(1): Command to run
#
# On Unix this is a passthrough. On Windows it wraps in bash -c since
# tools like bats have no native Windows port.
define run-in-bash
	$(if $(filter Windows_NT,$(OS)),bash -c "$(1)",$(1))
endef

################################################################################
# Help target
################################################################################

## Show this help message
## Lists all available targets with their descriptions
.PHONY: $(CONTAINER_BUILD_TOOLS_NAMESPACE)help
$(CONTAINER_BUILD_TOOLS_NAMESPACE)help:
	@printf "Container Build Tools - Available Targets\n\n"
	@color_enabled="$(HELP_COLOR_ENABLED)"; \
	if [ "$$color_enabled" = "1" ] && ! [ -t 1 ]; then \
		color_enabled=0; \
	fi; \
	awk -v docker_ns="$(DOCKER_TARGET_NAMESPACE)" \
	     -v gcloud_ns="$(GCLOUD_TARGET_NAMESPACE)" \
	     -v common_ns="$(CONTAINER_BUILD_TOOLS_NAMESPACE)" \
	     -v color_enabled="$$color_enabled" ' \
	function print_target(target) { \
		gsub(/\$$\(DOCKER_TARGET_NAMESPACE\)/, docker_ns, target); \
		gsub(/\$$\(GCLOUD_TARGET_NAMESPACE\)/, gcloud_ns, target); \
		gsub(/\$$\(CONTAINER_BUILD_TOOLS_NAMESPACE\)/, common_ns, target); \
		if (color_enabled == 1) { \
			printf "  \033[36m%-35s\033[0m %s\n", target, desc_lines[0]; \
		} else { \
			printf "  %-35s %s\n", target, desc_lines[0]; \
		} \
		for (i = 1; i < line_count; i++) { \
			printf "  %-35s %s\n", "", desc_lines[i]; \
		} \
		printf "\n"; \
		line_count = 0; \
		delete desc_lines; \
	} \
	/^##/ { \
		sub(/^## ?/, ""); \
		sub(/ *\\$$/, ""); \
		if (line_count == 0) { \
			desc_lines[0] = $$0; \
			line_count = 1; \
		} else { \
			desc_lines[line_count++] = $$0; \
		} \
		next \
	} \
	/^\.(PHONY|phony):/ && line_count > 0 { \
		print_target($$2); \
	} \
	/^[a-zA-Z0-9_-]+:/ && !/^\.(PHONY|phony):/ && !/:=/ && line_count > 0 { \
		target = $$1; \
		sub(/:.*$$/, "", target); \
		print_target(target); \
	} \
	{ if (!/^##/ && !/^\.(PHONY|phony):/ && !/^[a-zA-Z0-9_-]+:/) { line_count = 0; delete desc_lines; } }' $(MAKEFILE_LIST)
	@printf "\nUsage: make <target> [VARIABLE=value ...]\n"
	@printf "Example: make $(DOCKER_TARGET_NAMESPACE)docker-build DOCKER_IMAGE_NAME=myapp:latest\n"
	@printf "\nFor detailed documentation, see README.md\n"
