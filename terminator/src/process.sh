#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utility.sh"

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
    if terminator::utility::ask \
      "Kill process ${pid} <${name}> with signal ${signal}?"; then
      command kill "${signal}" "${pid}"
    fi
  done
}
