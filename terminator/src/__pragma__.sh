#!/bin/bash

# Bash source guard - prevents sourcing this file multiple times
[[ -n "${TERMINATOR_PRAGMA_LOADED}" ]] && return; readonly TERMINATOR_PRAGMA_LOADED=1

TERMINATOR_PRAGMA_LOADED_FILES=()

# Bash source guard helper like c #pragma once - will skip sourcing a file again if already sourced.
#
# Usage:
#   terminator::__pragma__::once || return 0 # File guard name defaults to the filepath
#   terminator::__pragma__::once MY_AWESOME_LIB || return 0 # File guard name is MY_AWESOME_LIB
#
# Returns:
#   0 - file should be sourced
#   1 - file should not be sourced
#
# Note this requires the `|| return 0` logical compound since bash source must exit early.
#
function terminator::__pragma__::once() {
  local guard_name="$1" \
    should_source_status=0 \
    should_not_source_status=1

  # Generates guard_name based on filename if none specified
  if [[ -z "${guard_name}" ]]; then
    # Fail-safe to source file if BASH_SOURCE stack only points to this file
    (( ${#BASH_SOURCE[@]} < 2 )) && return "${should_source_status}"

    local root_dir="${BASH_SOURCE[0]%/*/*/*}"
    local source_filepath="${BASH_SOURCE[1]/${root_dir}/}"

    guard_name="${source_filepath//[\/.\- ]/_}"
  fi

  local element
  for element in "${TERMINATOR_PRAGMA_LOADED_FILES[@]}"; do
    [[ "${element}" == "${guard_name}" ]] && return "${should_not_source_status}"
  done

  TERMINATOR_PRAGMA_LOADED_FILES+=("${guard_name}")

  return "${should_source_status}"
}

function terminator::__pragma__::clear() {
  TERMINATOR_PRAGMA_LOADED_FILES=()
}

function terminator::__pragma__::remove() {
  local element index
  for element in "$@"; do
    for index in "${!TERMINATOR_PRAGMA_LOADED_FILES[@]}"; do
      if [[ "${TERMINATOR_PRAGMA_LOADED_FILES[index]}" == "${element}" ]]; then
        unset 'TERMINATOR_PRAGMA_LOADED_FILES[index]'
      fi
    done
  done
}
