#!/bin/bash

function terminator::color::code() {
  if (( $# == 2 )) && [[ "$2" == 'bare' ]]; then
    printf '\x1b[%s' "$1"
    return
  fi

  printf '\[\x1b[%s\]' "$1"
}

function terminator::color::off() {
  terminator::color::code '0m'
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
      "$(terminator::color::code "38;5;${index}m" 'bare')" \
      "color${index}"
    (( ((index + 1) % 8) == 0 )) && { echo ''; }
  done
}