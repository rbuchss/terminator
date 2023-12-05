#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::version::compare() {
  [[ "$1" == "$2" ]] && return 0

  local index lhs rhs IFS=.

  read -r -a lhs <<< "$1"
  read -r -a rhs <<< "$2"

  # fill empty fields in lhs with zeros
  for (( index=${#lhs[@]}; index < ${#rhs[@]}; index++ )); do
    lhs[index]=0
  done

  for (( index=0; index < ${#lhs[@]}; index++ )); do
    if [[ -z "${rhs[index]}" ]]; then
      # fill empty fields in rhs with zeros
      rhs[index]=0
    fi

    (( 10#${lhs[index]} > 10#${rhs[index]} )) && return 1
    (( 10#${lhs[index]} < 10#${rhs[index]} )) && return 2
  done

  return 0
}

function terminator::version::__export__() {
  export -f terminator::version::compare
}

function terminator::version::__recall__() {
  export -fn terminator::version::compare
}

terminator::__module__::export
