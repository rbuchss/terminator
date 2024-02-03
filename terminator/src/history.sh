#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::history::__enable__() {
  alias hideme='history -d $((HISTCMD-1)) &&'
  alias hack='terminator::history::search'
  alias history_stats='terminator::history::stats'
}

function terminator::history::__disable__() {
  unalias hideme
  unalias hack
  unalias history_stats
}

function terminator::history::stats() {
  local number="${1:-15}"
  cut -f1 -d" " "${HOME}/.bash_history" \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n "${number}"
}

function terminator::history::search() {
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
        | "terminator::history::search::${search_command}" "$1" \
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

function terminator::history::search::rg() {
  command rg --color always "$@"
}

function terminator::history::search::ag() {
  command ag --color "$@"
}

function terminator::history::search::ack() {
  command ack --color "$@"
}

function terminator::history::search::grep() {
  command grep --color=always "$@"
}

function terminator::history::__export__() {
  export -f terminator::history::stats
  export -f terminator::history::search
  export -f terminator::history::search::rg
  export -f terminator::history::search::ag
  export -f terminator::history::search::ack
  export -f terminator::history::search::grep
}

function terminator::history::__recall__() {
  export -fn terminator::history::stats
  export -fn terminator::history::search
  export -fn terminator::history::search::rg
  export -fn terminator::history::search::ag
  export -fn terminator::history::search::ack
  export -fn terminator::history::search::grep
}

terminator::__module__::export
