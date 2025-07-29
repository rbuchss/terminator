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
  terminator::logger::log -l trace "$@"
}

function terminator::logger::debug {
  terminator::logger::log -l debug "$@"
}

function terminator::logger::info {
  terminator::logger::log -l info "$@"
}

function terminator::logger::warning {
  terminator::logger::log -l warning "$@"
}

function terminator::logger::error {
  terminator::logger::log -l error "$@"
}

function terminator::logger::fatal {
  terminator::logger::log -l fatal "$@"
}

function terminator::logger::log {
  terminator::logger::is_silenced && return

  local \
    level \
    caller_level=1 \
    output \
    severity \
    arguments=()

  level="$(terminator::logger::level_default)"
  output="$(terminator::logger::output_default)"

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::logger::logger::usage
        return "${TERMINATOR_LOG_INVALID_STATUS}"
        ;;
      -l | --level)
        shift
        level="$1"
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
        >&2 terminator::logger::logger::usage
        return "${TERMINATOR_LOG_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  [[ "${output}" == '/dev/null' ]] && return

  severity="$(terminator::logger::severity "${level}")"

  (( severity < $(terminator::logger::level) )) && return

  local datetime progname caller_info
  datetime="$(terminator::logger::datetime)"
  progname="${FUNCNAME[${caller_level}+1]}"

  case "${severity}" in
    "${TERMINATOR_LOG_SEVERITY_TRACE}") level='TRACE' ;;
    "${TERMINATOR_LOG_SEVERITY_DEBUG}") level='DEBUG' ;;
    "${TERMINATOR_LOG_SEVERITY_INFO}") level='INFO' ;;
    "${TERMINATOR_LOG_SEVERITY_WARNING}") level='WARNING' ;;
    "${TERMINATOR_LOG_SEVERITY_ERROR}") level='ERROR' ;;
    *)
      level='FATAL'
      caller_info="$(terminator::logger::stacktrace "${caller_level}")\n"
      ;;
  esac

  for message in "${arguments[@]}"; do
    printf '%s, [%s #%d] %7s -- %s: %b\n%b' \
      "${level:0:1}" \
      "${datetime}" \
      "$$" \
      "${level}" \
      "${progname}" \
      "${message}" \
      "${caller_info}" \
      >> "${output}"
  done
}

function terminator::logger::logger::usage {
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
    _level="$1" \
    _severity

  case "${_level}" in
    [Tt][Rr][Aa][Cc][Ee]) _severity="${TERMINATOR_LOG_SEVERITY_TRACE}" ;;
    [Dd][Ee][Bb][Uu][Gg]) _severity="${TERMINATOR_LOG_SEVERITY_DEBUG}" ;;
    [Ii][Nn][Ff][Oo]) _severity="${TERMINATOR_LOG_SEVERITY_INFO}" ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg]) _severity="${TERMINATOR_LOG_SEVERITY_WARNING}" ;;
    [Ee][Rr][Rr][Oo][Rr]) _severity="${TERMINATOR_LOG_SEVERITY_ERROR}" ;;
    *) _severity="${TERMINATOR_LOG_SEVERITY_FATAL}" ;;
  esac

  echo "${_severity}"
}

function terminator::logger::level {
  local variable default
  variable="$(terminator::logger::level::variable)"
  default="$(terminator::logger::level_default)"
  terminator::logger::severity "${!variable:-${default}}"
}

function terminator::logger::level_default {
  local variable
  variable="$(terminator::logger::level_default::variable)"
  echo "${!variable:-info}"
}

function terminator::logger::output_default {
  local variable
  variable="$(terminator::logger::output_default::variable)"
  echo "${!variable:-/dev/stderr}"
}

function terminator::logger::level::variable {
  echo "${TERMINATOR_LOG_LEVEL_VARIABLE:-TERMINATOR_LOG_LEVEL}"
}

function terminator::logger::level::set_variable {
  TERMINATOR_LOG_LEVEL_VARIABLE="$1"
}

function terminator::logger::level::unset_variable {
  unset TERMINATOR_LOG_LEVEL_VARIABLE
}

function terminator::logger::level_default::variable {
  echo "${TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE:-TERMINATOR_LOG_LEVEL_DEFAULT}"
}

function terminator::logger::level_default::set_variable {
  TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE="$1"
}

function terminator::logger::level_default::unset_variable {
  unset TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE
}

function terminator::logger::output_default::variable {
  echo "${TERMINATOR_LOG_OUTPUT_DEFAULT_VARIABLE:-TERMINATOR_LOG_OUTPUT_DEFAULT}"
}

function terminator::logger::output_default::set_variable {
  TERMINATOR_LOG_OUTPUT_DEFAULT_VARIABLE="$1"
}

function terminator::logger::output_default::unset_variable {
  unset TERMINATOR_LOG_OUTPUT_DEFAULT_VARIABLE
}

function terminator::logger::is_silenced {
  local silence
  silence="$(terminator::logger::silence)"
  (( silence == 1 ))
}

function terminator::logger::silence {
  local variable
  variable="$(terminator::logger::silence::variable)"
  echo "${!variable:-0}"
}

function terminator::logger::silence::variable {
  echo "${TERMINATOR_LOG_SILENCE_VARIABLE:-TERMINATOR_LOG_SILENCE}"
}

function terminator::logger::silence::set_variable {
  TERMINATOR_LOG_SILENCE_VARIABLE="$1"
}

function terminator::logger::silence::unset_variable {
  unset TERMINATOR_LOG_SILENCE_VARIABLE
}

function terminator::logger::stacktrace {
  local \
    _caller_level="${1:-0}" \
    _caller_info \
    _stack=()

  # Add extra +1 to account for this function
  (( _caller_level++ ))

  while true; do
    if ! _caller_info="$(caller "${_caller_level}")"; then
      break
    fi

    _stack+=("$(terminator::logger::caller_formatter "${_caller_info}")")

    (( _caller_level++ ))
  done

  if (( ${#_stack[@]} > 0 )); then
    echo ' -> Traceback (most recent call last):'
    printf '%s\n' "${_stack[@]}"
  else
    echo ' -> No Traceback (stack info not available!)'
  fi
}

function terminator::logger::caller_formatter {
  local \
    _line \
    _func \
    _src \
    _message

  read -r _line _func _src <<< "$@"

  if [[ -z "${_func}" ]]; then
    _func='(top level)'
  fi

  if [[ -z "${_src}" ]]; then
    _src='(no file)'
  fi

  printf -v _message '  %s\n    %s' \
    "${_func}" \
    "${_src}"

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
    && (( ${_line:-0} > 0 )); then
      printf -v _message '%s:%s' "${_message}" "${_line}"
  fi

  echo "${_message}"
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
  export -f terminator::logger::logger::usage
  export -f terminator::logger::datetime
  export -f terminator::logger::severity
  export -f terminator::logger::level
  export -f terminator::logger::level_default
  export -f terminator::logger::output_default
  export -f terminator::logger::level::variable
  export -f terminator::logger::level::set_variable
  export -f terminator::logger::level::unset_variable
  export -f terminator::logger::level_default::variable
  export -f terminator::logger::level_default::set_variable
  export -f terminator::logger::level_default::unset_variable
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
  export -fn terminator::logger::logger::usage
  export -fn terminator::logger::datetime
  export -fn terminator::logger::severity
  export -fn terminator::logger::level
  export -fn terminator::logger::level_default
  export -fn terminator::logger::output_default
  export -fn terminator::logger::level::variable
  export -fn terminator::logger::level::set_variable
  export -fn terminator::logger::level::unset_variable
  export -fn terminator::logger::level_default::variable
  export -fn terminator::logger::level_default::set_variable
  export -fn terminator::logger::level_default::unset_variable
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
}

terminator::__module__::export
