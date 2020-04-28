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
  printf '\e[0;31m%s\n\e[0m' 'plain'
  printf '\e[1;31m%s\n\e[0m' 'bold'
  printf '\e[0;91m%s\n\e[0m' 'highlight'
  printf '\e[1;91m%s\n\e[0m' 'bold+highlight'
}

function terminator::styles::color::demo() {
  for index in {0..255} ; do
    printf '%s%11s' \
      "$(terminator::styles::color::code "38;5;${index}m")" \
      "color${index}"
    (( ((index + 1) % 8) == 0 )) && { echo ''; }
  done
}

function terminator::styles::color::code() {
  printf '\x1b[%s' "$1"
}

function terminator::styles::color::off() {
  echo "\[\033[0m\]"
}

# unicode helper for lack of echo/printf code point
# support in bash < 4.2
function terminator::styles::unicode::code() {
  local code_point="$1"
  local ceiling=63
  local bits=128
  local output=''
  local reply

  (( code_point < 0x80 )) && {
    reply="$(terminator::styles::unicode::octal "${code_point}")"
    echo "${reply}"
    return
  }

  while (( code_point > ceiling )); do
    reply="$(terminator::styles::unicode::octal "$(( 0x80 | code_point & 0x3f ))")"
    output="${reply}${output}"
    (( code_point >>= 6, bits += ceiling + 1, ceiling >>= 1 ))
  done

  reply="$(terminator::styles::unicode::octal "$(( bits | code_point ))")"
  echo "${reply}${output}"
}

function terminator::styles::unicode::octal() {
  local octal
  printf -v octal '%03o' "$1"
  printf '%b' "\\${octal}"
}
