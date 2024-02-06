#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

terminator::__module__::load || return 0

TERMINATOR_COMMAND_LOG_LEVEL_DEFAULT='warning'
TERMINATOR_COMMAND_LOG_OUTPUT_STREAM="/dev/stderr"
TERMINATOR_COMMAND_LOG_OUTPUT_NONE='/dev/null'
TERMINATOR_COMMAND_INVALID_STATUS=255

function terminator::command::exists {
  local argument \
    log_level="${TERMINATOR_COMMAND_LOG_LEVEL_DEFAULT}" \
    log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_NONE}" \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      -l | --log-level)
        shift
        log_level="$1"
        ;;
      -v | --verbose)
        log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_STREAM}"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#arguments[@]} != 1 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]} invalid number of arguments: ${#arguments[@]} - must be 1"
    >&2 terminator::command::exists::usage
    return "${TERMINATOR_COMMAND_INVALID_STATUS}"
  fi

  argument="${arguments[0]}"

  if ! terminator::command::__exists__ "${argument}"; then
    terminator::log::logger -l "${log_level}" -o "${log_output}" "${argument} is not installed"
    return 1
  fi

  return 0
}

function terminator::command::any_exist {
  local argument \
    log_level="${TERMINATOR_COMMAND_LOG_LEVEL_DEFAULT}" \
    log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_NONE}" \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      -l | --log-level)
        shift
        log_level="$1"
        ;;
      -v | --verbose)
        log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_STREAM}"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#arguments[@]} == 0 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]} invalid number of arguments: ${#arguments[@]} - must be > 0"
    >&2 terminator::command::exists::usage
    return "${TERMINATOR_COMMAND_INVALID_STATUS}"
  fi

  for argument in "${arguments[@]}"; do
    terminator::command::__exists__ "${argument}" && return 0
  done

  terminator::log::logger -l "${log_level}" -o "${log_output}" "[${arguments[*]}] are not installed"
  return 1
}

function terminator::command::none_exist {
  local argument \
    log_level="${TERMINATOR_COMMAND_LOG_LEVEL_DEFAULT}" \
    log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_NONE}" \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      -l | --log-level)
        shift
        log_level="$1"
        ;;
      -v | --verbose)
        log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_STREAM}"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#arguments[@]} == 0 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]} invalid number of arguments: ${#arguments[@]} - must be > 0"
    >&2 terminator::command::exists::usage
    return "${TERMINATOR_COMMAND_INVALID_STATUS}"
  fi

  for argument in "${arguments[@]}"; do
    if terminator::command::__exists__ "${argument}"; then
      terminator::log::logger -l "${log_level}" -o "${log_output}" "${argument} is installed"
      return 1
    fi
  done

  return 0
}

function terminator::command::all_exist {
  local argument \
    log_level="${TERMINATOR_COMMAND_LOG_LEVEL_DEFAULT}" \
    log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_NONE}" \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      -l | --log-level)
        shift
        log_level="$1"
        ;;
      -v | --verbose)
        log_output="${TERMINATOR_COMMAND_LOG_OUTPUT_STREAM}"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::command::exists::usage
        return "${TERMINATOR_COMMAND_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#arguments[@]} == 0 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]} invalid number of arguments: ${#arguments[@]} - must be > 0"
    >&2 terminator::command::exists::usage
    return "${TERMINATOR_COMMAND_INVALID_STATUS}"
  fi

  for argument in "${arguments[@]}"; do
    if ! terminator::command::__exists__ "${argument}"; then
      terminator::log::logger -l "${log_level}" -o "${log_output}" "${argument} is not installed"
      return 1
    fi
  done

  return 0
}

function terminator::command::exists::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] <args>

  -l, --log-level    Log level
                     Default: ${TERMINATOR_COMMAND_LOG_LEVEL_DEFAULT}

  -v, --verbose      Enable logging. Disabled by default.

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::command::__exists__ {
  command -v "$1" > /dev/null 2>&1
}

function terminator::command::__export__ {
  export -f terminator::command::__exists__
  export -f terminator::command::exists
  export -f terminator::command::any_exist
  export -f terminator::command::none_exist
  export -f terminator::command::all_exist
  export -f terminator::command::exists::usage
}

function terminator::command::__recall__ {
  export -fn terminator::command::__exists__
  export -fn terminator::command::exists
  export -fn terminator::command::any_exist
  export -fn terminator::command::none_exist
  export -fn terminator::command::all_exist
  export -fn terminator::command::exists::usage
}

terminator::__module__::export
