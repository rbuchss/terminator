#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

terminator::__module__::load || return 0

function terminator::byte::__enable__ {
  alias reverse_endianness='terminator::byte::reverse_endianness'
}

function terminator::byte::__disable__ {
  unalias reverse_endianness
}

function terminator::byte::reverse_endianness {
  if (($# != 1)); then
    terminator::logger::error "invalid # of args: expected 1 argument" "Usage: ${FUNCNAME[0]} hex-value"
    return 1
  fi

  local value="$1"
  local index="${#value}"

  while ((index > 0)); do
    index=$((index - 2))
    echo -n "${value:$index:2}"
  done

  echo ''
}

function terminator::byte::__export__ {
  export -f terminator::byte::reverse_endianness
}

# KCOV_EXCL_START
function terminator::byte::__recall__ {
  export -fn terminator::byte::reverse_endianness
}
# KCOV_EXCL_STOP

terminator::__module__::export
