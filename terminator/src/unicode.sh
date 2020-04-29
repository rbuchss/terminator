#!/bin/bash

# unicode helper for lack of echo/printf code point
# support in bash < 4.2
function terminator::unicode::code() {
  local code_point="$1"
  local ceiling=63
  local bits=128
  local output=''
  local reply

  (( code_point < 0x80 )) && {
    reply="$(terminator::unicode::octal "${code_point}")"
    echo "${reply}"
    return
  }

  while (( code_point > ceiling )); do
    reply="$(terminator::unicode::octal "$(( 0x80 | code_point & 0x3f ))")"
    output="${reply}${output}"
    (( code_point >>= 6, bits += ceiling + 1, ceiling >>= 1 ))
  done

  reply="$(terminator::unicode::octal "$(( bits | code_point ))")"
  echo "${reply}${output}"
}

function terminator::unicode::octal() {
  local octal
  printf -v octal '%03o' "$1"
  printf '%b' "\\${octal}"
}
