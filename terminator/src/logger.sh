#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

readonly TERMINATOR_LOG_SEVERITY_TRACE=0
readonly TERMINATOR_LOG_SEVERITY_DEBUG=1
readonly TERMINATOR_LOG_SEVERITY_INFO=2
readonly TERMINATOR_LOG_SEVERITY_WARNING=3
readonly TERMINATOR_LOG_SEVERITY_ERROR=4
readonly TERMINATOR_LOG_SEVERITY_FATAL=5

readonly TERMINATOR_LOG_INVALID_STATUS=255

function terminator::logger::trace {
  terminator::logger::log \
    -l trace \
    -c 1 \
    "$@"
}

function terminator::logger::debug {
  terminator::logger::log \
    -l debug \
    -c 1 \
    "$@"
}

function terminator::logger::info {
  terminator::logger::log \
    -l info \
    -c 1 \
    "$@"
}

function terminator::logger::warning {
  terminator::logger::log \
    -l warning \
    -c 1 \
    "$@"
}

function terminator::logger::error {
  terminator::logger::log \
    -l error \
    -c 1 \
    "$@"
}

function terminator::logger::fatal {
  terminator::logger::log \
    -l fatal \
    -c 1 \
    "$@"
}

function terminator::logger::log {
  terminator::logger::is_silenced && return

  local \
    event_level \
    caller_level=0 \
    output \
    event_severity \
    logger_severity \
    arguments=()

  terminator::logger::level_default event_level
  terminator::logger::output_default output

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::logger::log::usage
        return "${TERMINATOR_LOG_INVALID_STATUS}"
        ;;
      -l | --level)
        shift
        event_level="$1"
        ;;
      -c | --caller-level)
        shift
        caller_level="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      # Stop processing options and treat all remaining as arguments.
      # This is consistent with POSIX standards.
      --)
        shift
        arguments+=("$@")
        break
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::logger::log::usage
        return "${TERMINATOR_LOG_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  [[ "${output}" == '/dev/null' ]] && return

  terminator::logger::severity_from_level "${event_level}" event_severity
  terminator::logger::severity logger_severity

  if [[ -z "${event_severity}" ]]; then
    >&2 echo "ERROR: ${FUNCNAME[0]} event_severity is null and invalid"
    return "${TERMINATOR_LOG_INVALID_STATUS}"
  fi

  if [[ -z "${logger_severity}" ]]; then
    >&2 echo "ERROR: ${FUNCNAME[0]} logger_severity is null and invalid"
    return "${TERMINATOR_LOG_INVALID_STATUS}"
  fi

  (( event_severity < logger_severity )) && return

  local \
    datetime \
    progname \
    caller_info

  datetime="$(terminator::logger::datetime)"
  progname="${FUNCNAME[${caller_level}+1]}"

  case "${event_severity}" in
    "${TERMINATOR_LOG_SEVERITY_TRACE}") event_level='TRACE' ;;
    "${TERMINATOR_LOG_SEVERITY_DEBUG}") event_level='DEBUG' ;;
    "${TERMINATOR_LOG_SEVERITY_INFO}") event_level='INFO' ;;
    "${TERMINATOR_LOG_SEVERITY_WARNING}") event_level='WARNING' ;;
    "${TERMINATOR_LOG_SEVERITY_ERROR}") event_level='ERROR' ;;
    *)
      event_level='FATAL'
      terminator::logger::stacktrace "${caller_level}" caller_info
      ;;
  esac

  for message in "${arguments[@]}"; do
    printf '%s, [%s #%d] %7s -- %s: %b\n%b' \
      "${event_level:0:1}" \
      "${datetime}" \
      "$$" \
      "${event_level}" \
      "${progname}" \
      "${message}" \
      "${caller_info}" \
      >> "${output}"
  done
}

function terminator::logger::log::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] # prints log message

  -c, --caller-level    Caller level
                        Default: 1

  -l, --level           Level
                        Default: $(terminator::logger::level_default)

  -o, --output          Output stream
                        Default: $(terminator::logger::output_default)

  -h, --help            Display this help message
USAGE_TEXT
}

function terminator::logger::datetime {
  local \
    found_command=0 \
    date_command \
    date_commands=(
      'date'
      '/bin/date'
    )

  for date_command in "${date_commands[@]}"; do
    if command -v "${date_command}" > /dev/null 2>&1; then
      found_command=1
      "${date_command}" '+%Y-%m-%dT%H:%M:%S%z'
      break
    fi
  done

  if (( found_command == 0 )); then
    echo ' NO-DATE-COMMAND-FOUND! '
  fi
}

function terminator::logger::severity {
  local \
    ___output_var___logger__severity="$1" \
    ___level___logger__severity

  terminator::logger::level ___level___logger__severity

  if [[ -n "${___output_var___logger__severity}" ]]; then
    terminator::logger::severity_from_level \
      "${___level___logger__severity}" \
      "${___output_var___logger__severity}"
  else
    terminator::logger::severity_from_level \
      "${___level___logger__severity}"
  fi
}

function terminator::logger::severity_from_level {
  local \
    ___level___logger__severity_from_level="$1" \
    ___output_var___logger__severity_from_level="$2" \
    ___severity___logger__severity_from_level

  case "${___level___logger__severity_from_level}" in
    [Tt][Rr][Aa][Cc][Ee])
      ___severity___logger__severity_from_level="${TERMINATOR_LOG_SEVERITY_TRACE}"
      ;;
    [Dd][Ee][Bb][Uu][Gg])
      ___severity___logger__severity_from_level="${TERMINATOR_LOG_SEVERITY_DEBUG}"
      ;;
    [Ii][Nn][Ff][Oo])
      ___severity___logger__severity_from_level="${TERMINATOR_LOG_SEVERITY_INFO}"
      ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg])
      ___severity___logger__severity_from_level="${TERMINATOR_LOG_SEVERITY_WARNING}"
      ;;
    [Ee][Rr][Rr][Oo][Rr])
      ___severity___logger__severity_from_level="${TERMINATOR_LOG_SEVERITY_ERROR}"
      ;;
    *)
      ___severity___logger__severity_from_level="${TERMINATOR_LOG_SEVERITY_FATAL}"
      ;;
  esac

  if [[ -n "${___output_var___logger__severity_from_level}" ]]; then
    printf \
      -v "${___output_var___logger__severity_from_level}" \
      '%s' \
      "${___severity___logger__severity_from_level}"
  else
    echo "${___severity___logger__severity_from_level}"
  fi
}

function terminator::logger::level {
  local \
    ___output_var___logger__level="$1" \
    ___ref___logger__level \
    ___default___logger__level

  terminator::logger::level::variable ___ref___logger__level
  terminator::logger::level_default ___default___logger__level

  if [[ -n "${___output_var___logger__level}" ]]; then
    printf \
      -v "${___output_var___logger__level}" \
      '%s' \
      "${!___ref___logger__level:-${___default___logger__level}}"
  else
    echo "${!___ref___logger__level:-${___default___logger__level}}"
  fi
}

function terminator::logger::level::variable {
  local \
    ___output_var___logger__level__variable="$1" \
    ___ref___logger__level__variable='TERMINATOR_LOG_LEVEL_VARIABLE' \
    ___default___logger__level__variable='TERMINATOR_LOG_LEVEL'

  if [[ -n "${___output_var___logger__level__variable}" ]]; then
    printf \
      -v "${___output_var___logger__level__variable}" \
      '%s' \
      "${!___ref___logger__level__variable:-${___default___logger__level__variable}}"
  else
    echo "${!___ref___logger__level__variable:-${___default___logger__level__variable}}"
  fi
}

function terminator::logger::level::set_variable {
  export TERMINATOR_LOG_LEVEL_VARIABLE="$1"
}

function terminator::logger::level::unset_variable {
  unset TERMINATOR_LOG_LEVEL_VARIABLE
}

function terminator::logger::level_default {
  local \
    ___output_var___logger__level_default="$1" \
    ___ref___logger__level_default \
    ___default___logger__level_default='info'

  terminator::logger::level_default::variable ___ref___logger__level_default

  if [[ -n "${___output_var___logger__level_default}" ]]; then
    printf \
      -v "${___output_var___logger__level_default}" \
      '%s' \
      "${!___ref___logger__level_default:-${___default___logger__level_default}}"
  else
    echo "${!___ref___logger__level_default:-${___default___logger__level_default}}"
  fi
}

function terminator::logger::level_default::variable {
  local \
    ___output_var___logger__level_default__variable="$1" \
    ___ref___logger__level_default__variable='TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE' \
    ___default___logger__level_default__variable='TERMINATOR_LOG_LEVEL_DEFAULT'

  if [[ -n "${___output_var___logger__level_default__variable}" ]]; then
    printf \
      -v "${___output_var___logger__level_default__variable}" \
      '%s' \
      "${!___ref___logger__level_default__variable:-${___default___logger__level_default__variable}}"
  else
    echo "${!___ref___logger__level_default__variable:-${___default___logger__level_default__variable}}"
  fi
}

function terminator::logger::level_default::set_variable {
  export TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE="$1"
}

function terminator::logger::level_default::unset_variable {
  unset TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE
}

function terminator::logger::output_default {
  local \
    ___output_var___logger__output_default="$1" \
    ___ref___logger__output_default \
    ___default___logger__output_default='/dev/stderr'

  terminator::logger::output_default::variable ___ref___logger__output_default

  if [[ -n "${___output_var___logger__output_default}" ]]; then
    printf \
      -v "${___output_var___logger__output_default}" \
      '%s' \
      "${!___ref___logger__output_default:-${___default___logger__output_default}}"
  else
    echo "${!___ref___logger__output_default:-${___default___logger__output_default}}"
  fi
}

function terminator::logger::output_default::variable {
  local \
    ___output_var___logger__output_default__variable="$1" \
    ___ref___logger__output_default__variable='TERMINATOR_LOG_OUTPUT_DEFAULT_VARIABLE' \
    ___default___logger__output_default__variable='TERMINATOR_LOG_OUTPUT_DEFAULT'

  if [[ -n "${___output_var___logger__output_default__variable}" ]]; then
    printf \
      -v "${___output_var___logger__output_default__variable}" \
      '%s' \
      "${!___ref___logger__output_default__variable:-${___default___logger__output_default__variable}}"
  else
    echo "${!___ref___logger__output_default__variable:-${___default___logger__output_default__variable}}"
  fi
}

function terminator::logger::output_default::set_variable {
  export TERMINATOR_LOG_OUTPUT_DEFAULT_VARIABLE="$1"
}

function terminator::logger::output_default::unset_variable {
  unset TERMINATOR_LOG_OUTPUT_DEFAULT_VARIABLE
}

function terminator::logger::is_silenced {
  local ___silence___logger__is_silenced

  terminator::logger::silence ___silence___logger__is_silenced

  case "${___silence___logger__is_silenced}" in
    0) ;;
    [Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|[1-9]|[1-9][0-9]*)
      ___silence___logger__is_silenced=1
      ;;
    *)
      ___silence___logger__is_silenced=0
      ;;
  esac

  (( ___silence___logger__is_silenced == 1 ))
}

function terminator::logger::silence {
  local \
    ___output_var___logger__silence="$1" \
    ___ref___logger__silence \
    ___default___logger__silence=0

  terminator::logger::silence::variable ___ref___logger__silence

  if [[ -n "${___output_var___logger__silence}" ]]; then
    printf \
      -v "${___output_var___logger__silence}" \
      '%s' \
      "${!___ref___logger__silence:-${___default___logger__silence}}"
  else
    echo "${!___ref___logger__silence:-${___default___logger__silence}}"
  fi
}

function terminator::logger::silence::variable {
  local \
    ___output_var___logger__silence__variable="$1" \
    ___ref___logger__silence__variable='TERMINATOR_LOG_SILENCE_VARIABLE' \
    ___default___logger__silence__variable='TERMINATOR_LOG_SILENCE'

  if [[ -n "${___output_var___logger__silence__variable}" ]]; then
    printf \
      -v "${___output_var___logger__silence__variable}" \
      '%s' \
      "${!___ref___logger__silence__variable:-${___default___logger__silence__variable}}"
  else
    echo "${!___ref___logger__silence__variable:-${___default___logger__silence__variable}}"
  fi
}

function terminator::logger::silence::set_variable {
  export TERMINATOR_LOG_SILENCE_VARIABLE="$1"
}

function terminator::logger::silence::unset_variable {
  unset TERMINATOR_LOG_SILENCE_VARIABLE
}

function terminator::logger::stacktrace {
  local \
    ___caller_level___logger__stacktrace="${1:-0}" \
    ___output_var___logger__stacktrace="$2" \
    ___caller_info___logger__stacktrace \
    ___message___logger__stacktrace \
    ___frame___logger__stacktrace \
    ___stack___logger__stacktrace=()

  # Add extra +1 to account for this function
  (( ___caller_level___logger__stacktrace++ ))

  while true; do
    if ! ___caller_info___logger__stacktrace="$(caller "${___caller_level___logger__stacktrace}")"; then
      break
    fi

    terminator::logger::caller_formatter \
      "${___caller_info___logger__stacktrace}" \
      ___frame___logger__stacktrace

    ___stack___logger__stacktrace+=("${___frame___logger__stacktrace}")

    (( ___caller_level___logger__stacktrace++ ))
  done

  if (( ${#___stack___logger__stacktrace[@]} > 0 )); then
    printf \
      -v ___message___logger__stacktrace \
      '%s\n' \
      "${___stack___logger__stacktrace[@]}"
    printf \
      -v ___message___logger__stacktrace \
      ' -> Traceback (most recent call last):\n%s' \
      "${___message___logger__stacktrace}"
  else
    printf \
      -v ___message___logger__stacktrace \
      ' -> No Traceback (stack info not available!)\n'
  fi

  if [[ -n "${___output_var___logger__stacktrace}" ]]; then
    printf \
      -v "${___output_var___logger__stacktrace}" \
      '%s' \
      "${___message___logger__stacktrace}"
  else
    echo "${___message___logger__stacktrace}"
  fi
}

function terminator::logger::caller_formatter {
  local \
    ___caller_info___logger__caller_formatter="$1" \
    ___output_var___logger__caller_formatter="$2" \
    ___line___logger__caller_formatter \
    ___func___logger__caller_formatter \
    ___file___logger__caller_formatter \
    ___message___logger__caller_formatter

  read -r \
    ___line___logger__caller_formatter \
    ___func___logger__caller_formatter \
    ___file___logger__caller_formatter \
    <<< "${___caller_info___logger__caller_formatter}"

  if [[ -z "${___func___logger__caller_formatter}" ]]; then
    ___func___logger__caller_formatter='(top level)'
  fi

  if [[ -z "${___file___logger__caller_formatter}" ]]; then
    ___file___logger__caller_formatter='(no file)'
  fi

  printf \
    -v ___message___logger__caller_formatter \
    '  %s\n    %s' \
    "${___func___logger__caller_formatter}" \
    "${___file___logger__caller_formatter}"

  # Note that the default, super old, version of bash that ships with macOS has
  # a bug where the caller/BASH_SOURCE[@] call stack gets corrupted and does
  # not report valid line numbers. So we check if the bash version is greater
  # than this version before including line numbers.
  #
  # BASH_VERSINFO[@] includes this version info - e.g. for macOS:
  #
  #   echo ${BASH_VERSINFO[@]}
  #   3 2 57 1 release arm64-apple-darwin24
  #
  # Here to keep things simple we just check if the version is greater than
  # 3 vs 3.2.57.
  #
  if (( ${BASH_VERSINFO[0]:-0} > 3 )) \
    && (( ${___line___logger__caller_formatter:-0} > 0 )); then
      printf \
        -v ___message___logger__caller_formatter \
        '%s:%s' \
        "${___message___logger__caller_formatter}" \
        "${___line___logger__caller_formatter}"
  fi

  if [[ -n "${___output_var___logger__caller_formatter}" ]]; then
    printf \
      -v "${___output_var___logger__caller_formatter}" \
      '%s' \
      "${___message___logger__caller_formatter}"
  else
    echo "${___message___logger__caller_formatter}"
  fi
}

function terminator::logger::__export__ {
  # We need to export the log functions for them to be accessible via xargs
  #
  # Helper script:
  # command rg --no-line-number 'function terminator::logger' terminator/src/logger.sh \
  #   | command rg -v 'terminator::logger::__' \
  #   | sed -E 's/function (.+)\(\) [{(]/export -f \1/' >> terminator/src/logger.sh
  #
  # NOTE: calling any exported function within terminator::__module__::load does not
  # play nice with tmux. Due to invalid function references across bash login shells.
  # To avoid this issue we need to either:
  #   - Not call any of these functions within tmux/terminator::__module__::load
  #   - Remove exports or unset these functions prior to calling tmux/terminator::__module__::load
  export -f terminator::logger::trace
  export -f terminator::logger::debug
  export -f terminator::logger::info
  export -f terminator::logger::warning
  export -f terminator::logger::error
  export -f terminator::logger::fatal
  export -f terminator::logger::log
  export -f terminator::logger::log::usage
  export -f terminator::logger::datetime
  export -f terminator::logger::severity
  export -f terminator::logger::severity_from_level
  export -f terminator::logger::level
  export -f terminator::logger::level::variable
  export -f terminator::logger::level::set_variable
  export -f terminator::logger::level::unset_variable
  export -f terminator::logger::level_default
  export -f terminator::logger::level_default::variable
  export -f terminator::logger::level_default::set_variable
  export -f terminator::logger::level_default::unset_variable
  export -f terminator::logger::output_default
  export -f terminator::logger::output_default::variable
  export -f terminator::logger::output_default::set_variable
  export -f terminator::logger::output_default::unset_variable
  export -f terminator::logger::is_silenced
  export -f terminator::logger::silence
  export -f terminator::logger::silence::variable
  export -f terminator::logger::silence::set_variable
  export -f terminator::logger::silence::unset_variable
  export -f terminator::logger::stacktrace
  export -f terminator::logger::caller_formatter

  # NOTE: we need to export the severity vars as well to avoid undefined vars in child shells.
  export TERMINATOR_LOG_SEVERITY_TRACE
  export TERMINATOR_LOG_SEVERITY_DEBUG
  export TERMINATOR_LOG_SEVERITY_INFO
  export TERMINATOR_LOG_SEVERITY_WARNING
  export TERMINATOR_LOG_SEVERITY_ERROR
  export TERMINATOR_LOG_SEVERITY_FATAL
  export TERMINATOR_LOG_INVALID_STATUS
}

function terminator::logger::__recall__ {
  # We need to remove these exported functions otherwise tmux will not
  # properly load the .bash_profile if any of them are called during
  # the bash --login process.
  #
  # Calling any will cause a corruption of the bash call stack based
  # on bash 3.2.57. This appears to be due corrupted function references
  # from the parent inherited env.
  #
  # To use these within tmux we must first remove these exported function
  # references and then re-init them just like we would with a new
  # bash --login session.
  export -fn terminator::logger::trace
  export -fn terminator::logger::debug
  export -fn terminator::logger::info
  export -fn terminator::logger::warning
  export -fn terminator::logger::error
  export -fn terminator::logger::fatal
  export -fn terminator::logger::log
  export -fn terminator::logger::log::usage
  export -fn terminator::logger::datetime
  export -fn terminator::logger::severity
  export -fn terminator::logger::severity_from_level
  export -fn terminator::logger::level
  export -fn terminator::logger::level::variable
  export -fn terminator::logger::level::set_variable
  export -fn terminator::logger::level::unset_variable
  export -fn terminator::logger::level_default
  export -fn terminator::logger::level_default::variable
  export -fn terminator::logger::level_default::set_variable
  export -fn terminator::logger::level_default::unset_variable
  export -fn terminator::logger::output_default
  export -fn terminator::logger::output_default::variable
  export -fn terminator::logger::output_default::set_variable
  export -fn terminator::logger::output_default::unset_variable
  export -fn terminator::logger::is_silenced
  export -fn terminator::logger::silence
  export -fn terminator::logger::silence::variable
  export -fn terminator::logger::silence::set_variable
  export -fn terminator::logger::silence::unset_variable
  export -fn terminator::logger::stacktrace
  export -fn terminator::logger::caller_formatter

  export -n TERMINATOR_LOG_SEVERITY_TRACE
  export -n TERMINATOR_LOG_SEVERITY_DEBUG
  export -n TERMINATOR_LOG_SEVERITY_INFO
  export -n TERMINATOR_LOG_SEVERITY_WARNING
  export -n TERMINATOR_LOG_SEVERITY_ERROR
  export -n TERMINATOR_LOG_SEVERITY_FATAL
  export -n TERMINATOR_LOG_INVALID_STATUS
}

terminator::__module__::export
