################################################################################
# Container Build Tools - Main Entry Point
################################################################################

# Determine the directory where this Makefile is located
# This ensures includes work correctly regardless of where make is invoked from
CONTAINER_BUILD_TOOLS_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

# Namespace for all targets (empty by default, can be overridden)
CONTAINER_BUILD_TOOLS_NAMESPACE ?=

# Include common utilities first
include $(CONTAINER_BUILD_TOOLS_DIR)/modules/common.mk

# Include all module makefiles using absolute paths
include $(CONTAINER_BUILD_TOOLS_DIR)/modules/docker.mk
