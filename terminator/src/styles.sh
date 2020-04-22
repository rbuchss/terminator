#!/bin/bash

function terminator::styles::newline() {
  # shellcheck disable=SC2028
  case "${OSTYPE}" in
    msys*) echo '\r\n' ;; # windows
    # solaris*) ;& # case fall-through not supported until bash-4
    # darwin*) ;&
    # linux*) ;&
    # bsd*) ;&
    *) echo '\n' ;;
  esac
}

function terminator::styles::highlight::demo() {
  printf '\e[0;31mplain\n\e[0m'
  printf '\e[1;31mbold\n\e[0m'
  printf '\e[0;91mhighlight\n\e[0m'
  printf '\e[1;91mbold+highlight\n\e[0m'
}

function terminator::styles::color::demo() {
  for index in {0..255} ; do
    printf '%s%11s' \
      "$(terminator::styles::color::code "38;5;${index}m")" \
      "color${index}"
    if [[ $(((index + 1) % 8)) == 0 ]]; then echo ''; fi
  done
}

function terminator::styles::color::code() {
  printf "\x1b[%s" "$1"
}

function terminator::styles::color::off() {
  echo "\[\033[0m\]"
}

