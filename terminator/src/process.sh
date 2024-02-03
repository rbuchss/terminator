#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/prompt.sh"

terminator::__module__::load || return 0

function terminator::process::__enable__() {
  alias kill_match='terminator::process::kill'
}

function terminator::process::__disable__() {
  unalias kill_match
}

function terminator::process::kill() {
  if (( $# < 1 )) || (( $# > 2 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]} invalid number of arguments"
    >&2 echo "Usage: ${FUNCNAME[0]} [-SIGNAL] pattern"
    return 1
  fi

  local pattern="${!#}"
  local pids=()
  local pid name signal='-TERM'

  if (( $# == 2 )); then
    signal="$1"
  fi

  while IFS='' read -r pid; do
    pids+=("${pid}")
  done < <(pgrep "${pattern}")

  printf "Found %d processes matching '%s'\n" \
    "${#pids}" \
    "${pattern}"

  (( ${#pids} == 0 )) && return

  ps -o 'pid,ppid,user,%cpu,%mem,tty,start,time,command' -p "${pids[@]}"

  echo ''

  for pid in "${pids[@]}"; do
    name="$(command ps -p "${pid}" -o args=)"
    if terminator::prompt::ask \
      "Kill process ${pid} <${name}> with signal ${signal}?"; then
      command kill "${signal}" "${pid}"
    fi
  done
}

function terminator::process::__export__() {
  export -f terminator::process::kill
}

function terminator::process::__recall__() {
  export -fn terminator::process::kill
}

terminator::__module__::export
