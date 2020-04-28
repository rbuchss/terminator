#!/bin/bash

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
