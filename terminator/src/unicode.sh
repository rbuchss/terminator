#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

# unicode helper for lack of echo/printf code point
# support in bash < 4.2
function terminator::unicode::code() {
  local code_point="$1"
  local ceiling=63
  local bits=128
  local output=''
  local reply

  (( code_point < 0x80 )) && {
    terminator::unicode::octal "${code_point}" reply
    case "$#" in
      # TODO should this be read -r ?
      2) printf -v "$2" '%s' "${reply}" ;;
      *) printf '%s' "${reply}" ;;
    esac
    return
  }

  while (( code_point > ceiling )); do
    terminator::unicode::octal "$(( 0x80 | code_point & 0x3f ))" reply
    output="${reply}${output}"
    (( code_point >>= 6, bits += ceiling + 1, ceiling >>= 1 ))
  done

  terminator::unicode::octal "$(( bits | code_point ))" reply

  case "$#" in
    2) printf -v "$2" '%s%s' "${reply}" "${output}" ;;
    *) printf '%s%s' "${reply}" "${output}" ;;
  esac
}

function terminator::unicode::octal() {
  local octal
  printf -v octal '%03o' "$1"
  printf -v "$2" '%b' "\\${octal}"
}
