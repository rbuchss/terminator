#!/bin/bash

function terminator::utility::ask() {
  echo -n "$@" '[y/n] '
  read -r response
  case "${response}" in
    y*|Y*) return 0 ;;
    *) return 1 ;;
  esac
}

function terminator::utility::history_stats() {
  local number="${1:-15}"
  cut -f1 -d" " "${HOME}/.bash_history" \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n "${number}"
}

function terminator::utility::hack() {
  if command -v ag > /dev/null 2>&1; then
    history | ag "$1"
  else
    history | grep "$1"
  fi
}

function terminator::utility::reverse_endianness() {
  if (( $# != 1 )); then
    >&2 echo 'ERROR: invalid # of args: expected 1 argument'
    >&2 echo "Usage: ${FUNCNAME[0]} hex-value"
    return 1
  fi

  local value="$1"
  local index="${#value}"

  while (( index > 0 )); do
    index=$((index - 2))
    echo -n "${value:$index:2}"
  done

  echo ''
}

function terminator::utility::trace_environment() {
  PS4='+$BASH_SOURCE> ' BASH_XTRACEFD=7 bash -xl 7>&2
}
