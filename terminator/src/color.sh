#!/bin/bash

function terminator::color::code() {
  case "$#" in
    2) printf -v "$2" '\[\x1b[%s\]' "$1" ;;
    1) printf '\[\x1b[%s\]' "$1" ;;
    *) >&2 echo 'ERROR: invalid # of args' ;;
  esac
}

function terminator::color::code_bare() {
  case "$#" in
    2) printf -v "$2" '\x1b[%s' "$1" ;;
    1) printf '\x1b[%s' "$1" ;;
    *) >&2 echo 'ERROR: invalid # of args' ;;
  esac
}

function terminator::color::off() {
  terminator::color::code '0m' "$@"
}

# shellcheck disable=SC2120
function terminator::color::off_bare() {
  terminator::color::code_bare '0m' "$@"
}

function terminator::color::highlight_demo() {
  printf '\e[0;31m%s\n\e[0m' 'plain'
  printf '\e[1;31m%s\n\e[0m' 'bold'
  printf '\e[0;91m%s\n\e[0m' 'highlight'
  printf '\e[1;91m%s\n\e[0m' 'bold+highlight'
}

function terminator::color::demo() {
  for index in {0..255} ; do
    printf '%s%11s' \
      "$(terminator::color::code_bare "38;5;${index}m")" \
      "color${index}"
    (( ((index + 1) % 8) == 0 )) && { echo ''; }
  done
  # shellcheck disable=SC2119
  terminator::color::off_bare
}
