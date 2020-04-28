#!/bin/bash

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

function terminator::log::logger() (
  terminator::log::is_silenced && return

  function usage() {
    >&2 echo "Usage: ${FUNCNAME[1]} [-clo] # prints log message"
    >&2 echo "    -c: caller level (default: 1)"
    >&2 echo "    -l: level (default: info)"
    >&2 echo "    -o: output (default: /dev/stderr)"
  }

  local OPTIND flag
  local level='info'
  local caller_level=1
  local output=/dev/stderr
  local severity

  while getopts 'c:l:o:' flag; do
    case "${flag}" in
      c) caller_level="${OPTARG}" ;;
      l) level="${OPTARG}" ;;
      o) output="${OPTARG}" ;;
      *)
        usage
        return 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  severity="$(terminator::log::severity "${level}")"

  (( severity < $(terminator::log::level) )) && return

  local datetime progname caller_info
  datetime="$(date +%Y-%m-%dT%H:%M:%S%z)"
  progname="${FUNCNAME[${caller_level}+1]}"

  case "${level}" in
    debug) level='DEBUG' ;;
    info)level='INFO' ;;
    warning) level='WARNING' ;;
    *)
      level='ERROR'
      caller_info=" -> from: $(terminator::log::caller_formatter \
        "$(caller "${caller_level}")")\n"
      ;;
  esac

  for message in "$@"; do
    printf '%s, [%s #%d] %7s -- %s: %s\n%b' \
      "${level:0:1}" \
      "${datetime}" \
      "$$" \
      "${level}" \
      "${progname}" \
      "${message}" \
      "${caller_info}" \
      >> "${output}"
  done
)

function terminator::log::severity() {
  local severity
  case "$1" in
    debug|DEBUG) severity=0 ;;
    info|INFO) severity=1 ;;
    warning|WARNING) severity=2 ;;
    *) severity=3 ;;
  esac

  echo "${severity}"
}

function terminator::log::level() {
  local variable
  variable="$(terminator::log::level::variable)"
  terminator::log::severity "${!variable:-warning}"
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
