#!/bin/bash

function terminator::utility::ask() {
  echo -n "$*" '[y/n] '
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
  local found_command=0 \
    search_command \
    search_commands=(
      'rg'
      'ag'
      'ack'
      'grep'
    )

  for search_command in "${search_commands[@]}"; do
    if command -v "${search_command}" > /dev/null 2>&1; then
      found_command=1
      history \
        | "terminator::utility::hack::${search_command}" "$1" \
        | less \
          --quit-if-one-screen \
          --RAW-CONTROL-CHARS \
          --no-init
      break
    fi
  done

  if (( found_command == 0 )); then
    terminator::log::error "No possible search commands found: [${search_commands[*]}]"
    return 1
  fi
}

function terminator::utility::hack::rg() {
  command rg --color always "$@"
}

function terminator::utility::hack::ag() {
  command ag --color "$@"
}

function terminator::utility::hack::ack() {
  command ack --color "$@"
}

function terminator::utility::hack::grep() {
  command grep --color=always "$@"
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
