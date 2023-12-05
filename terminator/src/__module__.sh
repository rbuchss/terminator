#!/bin/bash

# Bash source guard - prevents sourcing this file multiple times
[[ -n "${TERMINATOR__MODULE__LOADED}" ]] && return; readonly TERMINATOR__MODULE__LOADED=1

TERMINATOR_MODULES_LOADED=()
TERMINATOR_MODULES_EXPORTED=()
TERMINATOR_MODULES_ENABLED=()

TERMINATOR_MODULE_LOAD_ACTION='__load__'
TERMINATOR_MODULE_UNLOAD_ACTION='__unload__'
TERMINATOR_MODULE_EXPORT_ACTION='__export__'
TERMINATOR_MODULE_RECALL_ACTION='__recall__'
TERMINATOR_MODULE_ENABLE_ACTION='__enable__'
TERMINATOR_MODULE_DISABLE_ACTION='__disable__'

# Bash source guard helper like c #pragma once - will skip sourcing a file again if already sourced.
#
# Usage:
#   terminator::__module__::load || return 0 # File guard name defaults to the filepath derived module name
#   terminator::__module__::load MY_AWESOME_LIB || return 0 # File guard name is MY_AWESOME_LIB
#
# Returns:
#   0 - file should be sourced
#   1 - file should not be sourced
#
# Note this requires the `|| return 0` logical compound since bash source must exit early.
#
function terminator::__module__::load() {
  local module="$1" \
    should_source_status=0 \
    should_not_source_status=1

  # Generates module based on filename if none specified
  if [[ -z "${module}" ]]; then
    # Fail-safe to source file if BASH_SOURCE stack only points to this file
    if ! terminator::__module__::__get_module_name__ module; then
      return 1
    fi
  fi

  if terminator::__module__::__action__ \
    "${module}" \
    "${TERMINATOR_MODULE_LOAD_ACTION}"; then
        TERMINATOR_MODULES_LOADED+=("${module}")

        if terminator::__module__::__function_exists__ 'terminator::log::trace'; then
          local trace_message
          printf -v trace_message '  %s\n' "${TERMINATOR_MODULES_LOADED[@]}"
          terminator::log::trace -- "-> TERMINATOR_MODULES_LOADED: [\n${trace_message}]"
        fi

        return "${should_source_status}"
  else
    return "${should_not_source_status}"
  fi
}

function terminator::__module__::load::clear() {
  TERMINATOR_MODULES_LOADED=()
}

function terminator::__module__::is_loaded() {
  local module="$1"

  terminator::__module__::__is_in_state__ \
    "${module}" \
    "${TERMINATOR_MODULE_LOAD_ACTION}" \
    3
}

function terminator::__module__::unload() {
  local module \
    modules=("$@")

  # Generates module based on filename if none specified
  if (( ${#modules[@]} == 0 )); then
    # Fail-safe to source file if BASH_SOURCE stack only points to this file
    if ! terminator::__module__::__get_module_name__ module; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if terminator::__module__::__action__ \
      "${module}" \
      "${TERMINATOR_MODULE_UNLOAD_ACTION}"; then
          for index in "${!TERMINATOR_MODULES_LOADED[@]}"; do
            if [[ "${TERMINATOR_MODULES_LOADED[index]}" == "${module}" ]]; then
              unset 'TERMINATOR_MODULES_LOADED[index]'
              break # no duplicates should exist so exit early is fine
            fi
          done
    fi
  done
}

function terminator::__module__::is_unloaded() {
  local module="$1"

  terminator::__module__::__is_in_state__ \
    "${module}" \
    "${TERMINATOR_MODULE_UNLOAD_ACTION}" \
    3
}

function terminator::__module__::export() {
  local module \
    modules=("$@")

  # Generates module based on filename if none specified
  if (( ${#modules[@]} == 0 )); then
    if ! terminator::__module__::__get_module_name__ module; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if terminator::__module__::__action__ \
      "${module}" \
      "${TERMINATOR_MODULE_EXPORT_ACTION}" \
      'terminator::__module__::__action__::__module_action_handler__'; then
          TERMINATOR_MODULES_EXPORTED+=("${module}")

          if terminator::__module__::__function_exists__ 'terminator::log::trace'; then
            local trace_message
            printf -v trace_message '  %s\n' "${TERMINATOR_MODULES_EXPORTED[@]}"
            terminator::log::trace -- "-> TERMINATOR_MODULES_EXPORTED: [\n${trace_message}]"
          fi
    fi
  done
}

function terminator::__module__::export::clear() {
  TERMINATOR_MODULES_EXPORTED=()
}

function terminator::__module__::is_exported() {
  local module="$1"

  terminator::__module__::__is_in_state__ \
    "${module}" \
    "${TERMINATOR_MODULE_EXPORT_ACTION}" \
    3
}

function terminator::__module__::recall() {
  local module \
    modules=("$@")

  # Generates module based on filename if none specified
  if (( ${#modules[@]} == 0 )); then
    if ! terminator::__module__::__get_module_name__ module; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if terminator::__module__::__action__ \
      "${module}" \
      "${TERMINATOR_MODULE_RECALL_ACTION}" \
      'terminator::__module__::__action__::__module_action_handler__'; then
          for index in "${!TERMINATOR_MODULES_EXPORTED[@]}"; do
            if [[ "${TERMINATOR_MODULES_EXPORTED[index]}" == "${module}" ]]; then
              unset 'TERMINATOR_MODULES_EXPORTED[index]'
              break # no duplicates should exist so exit early is fine
            fi
          done
    fi
  done
}

function terminator::__module__::is_recalled() {
  local module="$1"

  terminator::__module__::__is_in_state__ \
    "${module}" \
    "${TERMINATOR_MODULE_RECALL_ACTION}" \
    3
}

function terminator::__module__::enable() {
  local module \
    modules=("$@")

  # Generates module based on filename if none specified
  if (( ${#modules[@]} == 0 )); then
    if ! terminator::__module__::__get_module_name__ module; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if terminator::__module__::__action__ \
      "${module}" \
      "${TERMINATOR_MODULE_ENABLE_ACTION}" \
      'terminator::__module__::__action__::__module_action_handler__'; then
          TERMINATOR_MODULES_ENABLED+=("${module}")

          if terminator::__module__::__function_exists__ 'terminator::log::trace'; then
            local trace_message
            printf -v trace_message '  %s\n' "${TERMINATOR_MODULES_ENABLED[@]}"
            terminator::log::trace -- "-> TERMINATOR_MODULES_ENABLED: [\n${trace_message}]"
          fi
    fi
  done
}

function terminator::__module__::enable::clear() {
  TERMINATOR_MODULES_ENABLED=()
}

function terminator::__module__::is_enabled() {
  local module="$1"

  terminator::__module__::__is_in_state__ \
    "${module}" \
    "${TERMINATOR_MODULE_ENABLE_ACTION}" \
    3
}

function terminator::__module__::disable() {
  local module \
    modules=("$@")

  # Generates module based on filename if none specified
  if (( ${#modules[@]} == 0 )); then
    if ! terminator::__module__::__get_module_name__ module; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if terminator::__module__::__action__ \
      "${module}" \
      "${TERMINATOR_MODULE_DISABLE_ACTION}" \
      'terminator::__module__::__action__::__module_action_handler__'; then
          for index in "${!TERMINATOR_MODULES_ENABLED[@]}"; do
            if [[ "${TERMINATOR_MODULES_ENABLED[index]}" == "${module}" ]]; then
              unset 'TERMINATOR_MODULES_ENABLED[index]'
              break # no duplicates should exist so exit early is fine
            fi
          done
    fi
  done
}

function terminator::__module__::is_disabled() {
  local module="$1"

  terminator::__module__::__is_in_state__ \
    "${module}" \
    "${TERMINATOR_MODULE_DISABLE_ACTION}" \
    3
}

function terminator::__module__::__action__() {
  local module="$1" \
    action="$2" \
    handler="$3" \
    module_action_function

  case "${action}" in
    "${TERMINATOR_MODULE_LOAD_ACTION}") ;;
    "${TERMINATOR_MODULE_UNLOAD_ACTION}") ;;
    "${TERMINATOR_MODULE_EXPORT_ACTION}") ;;
    "${TERMINATOR_MODULE_RECALL_ACTION}") ;;
    "${TERMINATOR_MODULE_ENABLE_ACTION}") ;;
    "${TERMINATOR_MODULE_DISABLE_ACTION}") ;;
    *)
      terminator::__module__::__invoke_function_if_exists__ \
        'terminator::log::error' -c 2 \
        "Action: '${action}' is not valid"
      return 2
      ;;
  esac

  # Guard to do module only if not already in desired state
  if terminator::__module__::__is_in_state__ "${module}" "${action}"; then
    terminator::__module__::__invoke_function_if_exists__ \
      'terminator::log::trace' -c 3 \
      "Skipping: '${module}' since it is already in ${action} state"

    return 1
  fi

  if [[ -n "${handler}" ]]; then
    "${handler}" "${module}" "${action}"
  fi
}

function terminator::__module__::__action__::__module_action_handler__() {
  local module="$1" \
    action="$2" \
    module_action_function

  module_action_function="${module}::${action}"

  if ! terminator::__module__::__function_exists__ "${module_action_function}"; then
    terminator::__module__::__invoke_function_if_exists__ \
      'terminator::log::warning' -c 4 \
      "Skipping: '${module}' since it has no ${module_action_function} function defined"

    return 2
  fi

  terminator::__module__::__invoke_function_if_exists__ \
    'terminator::log::trace' -c 4 "Invoking: '${module_action_function}'"

  "${module_action_function}"
}

function terminator::__module__::__is_in_state__() {
  local module="$1" \
    action="$2" \
    log_caller_level="${3:-4}" \
    in_cache_response=0 \
    not_in_cache_response=1 \
    cache_element \
    cache=()

  case "${action}" in
    "${TERMINATOR_MODULE_LOAD_ACTION}")
      cache=("${TERMINATOR_MODULES_LOADED[@]}")
      ;;
    "${TERMINATOR_MODULE_UNLOAD_ACTION}")
      cache=("${TERMINATOR_MODULES_LOADED[@]}")
      in_cache_response=1
      not_in_cache_response=0
      ;;
    "${TERMINATOR_MODULE_EXPORT_ACTION}")
      cache=("${TERMINATOR_MODULES_EXPORTED[@]}")
      ;;
    "${TERMINATOR_MODULE_RECALL_ACTION}")
      cache=("${TERMINATOR_MODULES_EXPORTED[@]}")
      in_cache_response=1
      not_in_cache_response=0
      ;;
    "${TERMINATOR_MODULE_ENABLE_ACTION}")
      cache=("${TERMINATOR_MODULES_ENABLED[@]}")
      ;;
    "${TERMINATOR_MODULE_DISABLE_ACTION}")
      cache=("${TERMINATOR_MODULES_ENABLED[@]}")
      in_cache_response=1
      not_in_cache_response=0
      ;;
    *)
      terminator::__module__::__invoke_function_if_exists__ \
        'terminator::log::error' -c "${log_caller_level}" \
        "Action: '${action}' is not valid"
      return 2
      ;;
  esac

  for cache_element in "${cache[@]}"; do
    if [[ "${module}" == "${cache_element}" ]]; then
      return "${in_cache_response}"
    fi
  done

  return "${not_in_cache_response}"
}

function terminator::__module__::__function_exists__() {
  declare -F "$1" > /dev/null 2>&1
}

function terminator::__module__::__invoke_function_if_exists__() {
  if terminator::__module__::__function_exists__ "$1"; then
    "$1" "${@:2}"
  fi
}

function terminator::__module__::__get_guard_name__() {
  local _output_var="$1" \
    _root_index="${2:-1}" \
    _source_index="${3:-2}" \
    _source_filepath \
    _guard_name

  if ! terminator::__module__::__get_source_filepath__ \
    _source_filepath \
    $(( _root_index + 1 )) \
    $(( _source_index + 1 )); then
      return 1
  fi

  _guard_name="${_source_filepath//[\/.\- ]/_}"

  terminator::__module__::__invoke_function_if_exists__ \
    'terminator::log::trace' -c 3 "Using guard name: '${_guard_name}' for file: '${BASH_SOURCE[_source_index]}'"

  printf -v "${_output_var}" '%s' "${_guard_name}"
}

function terminator::__module__::__get_module_name__() {
  local _output_var="$1" \
    _root_index="${2:-1}" \
    _source_index="${3:-2}" \
    _source_filepath \
    _module

  if ! terminator::__module__::__get_source_filepath__ \
    _source_filepath \
    $(( _root_index + 1 )) \
    $(( _source_index + 1 )); then
      return 1
  fi

  _module="${_source_filepath//[\/.\- ]/_}"
  _module="${_module//__/}"
  _module="${_module//_src/}"
  _module="${_module//_sh/}"
  _module="${_module//_/::}"

  terminator::__module__::__invoke_function_if_exists__ \
    'terminator::log::trace' -c 3 "Using module name: '${_module}' for file: '${BASH_SOURCE[_source_index]}'"

  printf -v "${_output_var}" '%s' "${_module}"
}

function terminator::__module__::__get_source_filepath__() {
  local __output_var="$1" \
    __root_index="${2:-1}" \
    __source_index="${3:-2}" \
    __root_dir \
    __source_filepath

  # Fail-safe if BASH_SOURCE stack only points to this file
  # Generates error since this function will not work.
  (( ${#BASH_SOURCE[@]} < __source_index )) && return 1

  __root_dir="${BASH_SOURCE[__root_index]%/*/*/*}"
  __source_filepath="${BASH_SOURCE[__source_index]/${__root_dir}/}"

  printf -v "${__output_var}" '%s' "${__source_filepath}"
}
