THIS_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

include $(THIS_DIR)/../../vendor/container-build-tools/modules.mk

.DEFAULT_GOAL := docker-build

################################################################################
# Docker build defaults
################################################################################

DOCKER_IMAGE_NAME := rbuchss/terminator-tester-builder
DOCKER_BUILD_TARGET := terminator-tester-builder

DOCKER_IMAGE_BASH_VERSION := 3.2.57
DOCKER_IMAGE_BASH_PATH := /usr/local/bin/bash
DOCKER_IMAGE_KCOV_VERSION := v42

DOCKER_BUILD_FLAGS := \
  --build-arg IMAGE_BASH_VERSION=$(DOCKER_IMAGE_BASH_VERSION) \
  --build-arg IMAGE_BASH_PATH=$(DOCKER_IMAGE_BASH_PATH) \
  --build-arg IMAGE_KCOV_VERSION=$(DOCKER_IMAGE_KCOV_VERSION)

################################################################################
# Docker buildx defaults
################################################################################

DOCKER_BUILD_STRATEGY := buildx
DOCKER_BUILD_PLATFORM := linux/amd64,linux/arm64
DOCKER_BUILDX_BUILDER_NAME := doctor-miles-bennett-dyson

################################################################################
# Docker run defaults
################################################################################

DOCKER_DEBUG_CMD := $(DOCKER_IMAGE_BASH_PATH)
