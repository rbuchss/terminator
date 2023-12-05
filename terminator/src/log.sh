#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::log::trace() {
  terminator::log::logger -l trace "$@"
}

function terminator::log::debug() {
  terminator::log::logger -l debug "$@"
}

function terminator::log::info() {
  terminator::log::logger -l info "$@"
}

function terminator::log::warning() {
  terminator::log::logger -l warning "$@"
}

function terminator::log::error() {
  terminator::log::logger -l error "$@"
}

function terminator::log::logger() {
  terminator::log::is_silenced && return

  local OPTIND flag
  local level
  local caller_level=1
  local output=/dev/stderr
  local severity

  level="$(terminator::log::level_default)"

  while getopts 'c:l:o:' flag; do
    case "${flag}" in
      c) caller_level="${OPTARG}" ;;
      l) level="${OPTARG}" ;;
      o) output="${OPTARG}" ;;
      *)
        terminator::log::logger::usage >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  severity="$(terminator::log::severity "${level}")"

  (( severity < $(terminator::log::level) )) && return

  local datetime progname caller_info
  datetime="$(terminator::log::datetime)"
  progname="${FUNCNAME[${caller_level}+1]}"

  case "${level}" in
    [Tt][Rr][Aa][Cc][Ee]) level='TRACE' ;;
    [Dd][Ee][Bb][Uu][Gg]) level='DEBUG' ;;
    [Ii][Nn][Ff][Oo]) level='INFO' ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg]) level='WARNING' ;;
    *)
      level='ERROR'
      caller_info=" -> from: $(terminator::log::caller_formatter \
        "$(caller "${caller_level}")")\n"
      ;;
  esac

  for message in "$@"; do
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

function terminator::log::logger::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] # prints log message

    -c    Caller level
          Default: 1

    -l    Level
          Default: $(terminator::log::level_default)

    -o    Output stream
          Default: /dev/stderr
USAGE_TEXT
}

function terminator::log::datetime() {
  local found_command=0 \
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

function terminator::log::severity() {
  local severity
  case "$1" in
    [Tt][Rr][Aa][Cc][Ee]) severity=0 ;;
    [Dd][Ee][Bb][Uu][Gg]) severity=1 ;;
    [Ii][Nn][Ff][Oo]) severity=2 ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg]) severity=3 ;;
    *) severity=4 ;;
  esac

  echo "${severity}"
}

function terminator::log::level() {
  local variable default
  variable="$(terminator::log::level::variable)"
  default="$(terminator::log::level_default)"
  terminator::log::severity "${!variable:-${default}}"
}

function terminator::log::level_default() {
  local variable
  variable="$(terminator::log::level_default::variable)"
  echo "${!variable:-info}"
}

function terminator::log::level::variable() {
  echo "${TERMINATOR_LOG_LEVEL_VARIABLE:-TERMINATOR_LOG_LEVEL}"
}

function terminator::log::level::set_variable() {
  TERMINATOR_LOG_LEVEL_VARIABLE="$1"
}

function terminator::log::level::unset_variable() {
  unset TERMINATOR_LOG_LEVEL_VARIABLE
}

function terminator::log::level_default::variable() {
  echo "${TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE:-TERMINATOR_LOG_LEVEL_DEFAULT}"
}

function terminator::log::level_default::set_variable() {
  TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE="$1"
}

function terminator::log::level_default::unset_variable() {
  unset TERMINATOR_LOG_LEVEL_DEFAULT_VARIABLE
}

function terminator::log::is_silenced() {
  local silence
  silence="$(terminator::log::silence)"
  (( silence == 1 ))
}

function terminator::log::silence() {
  local variable
  variable="$(terminator::log::silence::variable)"
  echo "${!variable:-0}"
}

function terminator::log::silence::variable() {
  echo "${TERMINATOR_LOG_SILENCE_VARIABLE:-TERMINATOR_LOG_SILENCE}"
}

function terminator::log::silence::set_variable() {
  TERMINATOR_LOG_SILENCE_VARIABLE="$1"
}

function terminator::log::silence::unset_variable() {
  unset TERMINATOR_LOG_SILENCE_VARIABLE
}

function terminator::log::caller_formatter() {
  read -r -a array <<< "$@"
  for index in "${!array[@]}"; do
    case "${index}" in
      0) echo -n "line: ${array[${index}]}, " ;;
      1) echo -n "function: ${array[${index}]}, " ;;
      *)
        echo -n "file: ${array[*]:${index}}"
        break
        ;;
    esac
  done
  echo ''
}

function terminator::log::__export__() {
  # We need to export the log functions for them to be accessible via xargs
  #
  # Helper script:
  # command rg --no-line-number 'function terminator::log' terminator/src/log.sh \
  #   | command rg -v 'terminator::log::__' \
  #   | sed -E 's/function (.+)\(\) [{(]/export -f \1/' >> terminator/src/log.sh
  #
  # NOTE: calling any exported function within terminator::__module__::load does not
  # play nice with tmux. Due to invalid function references across bash login shells.
  # To avoid this issue we need to either:
  #   - Not call any of these functions within tmux/terminator::__module__::load
  #   - Remove exports or unset these functions prior to calling tmux/terminator::__module__::load
  export -f terminator::log::trace
  export -f terminator::log::debug
  export -f terminator::log::info
  export -f terminator::log::warning
  export -f terminator::log::error
  export -f terminator::log::logger
  export -f terminator::log::logger::usage
  export -f terminator::log::datetime
  export -f terminator::log::severity
  export -f terminator::log::level
  export -f terminator::log::level_default
  export -f terminator::log::level::variable
  export -f terminator::log::level::set_variable
  export -f terminator::log::level::unset_variable
  export -f terminator::log::level_default::variable
  export -f terminator::log::level_default::set_variable
  export -f terminator::log::level_default::unset_variable
  export -f terminator::log::is_silenced
  export -f terminator::log::silence
  export -f terminator::log::silence::variable
  export -f terminator::log::silence::set_variable
  export -f terminator::log::silence::unset_variable
  export -f terminator::log::caller_formatter
}

function terminator::log::__recall__() {
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
  export -fn terminator::log::trace
  export -fn terminator::log::debug
  export -fn terminator::log::info
  export -fn terminator::log::warning
  export -fn terminator::log::error
  export -fn terminator::log::logger
  export -fn terminator::log::logger::usage
  export -fn terminator::log::datetime
  export -fn terminator::log::severity
  export -fn terminator::log::level
  export -fn terminator::log::level_default
  export -fn terminator::log::level::variable
  export -fn terminator::log::level::set_variable
  export -fn terminator::log::level::unset_variable
  export -fn terminator::log::level_default::variable
  export -fn terminator::log::level_default::set_variable
  export -fn terminator::log::level_default::unset_variable
  export -fn terminator::log::is_silenced
  export -fn terminator::log::silence
  export -fn terminator::log::silence::variable
  export -fn terminator::log::silence::set_variable
  export -fn terminator::log::silence::unset_variable
  export -fn terminator::log::caller_formatter
}

terminator::__module__::export
