#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

terminator::__module__::load || return 0

function terminator::number::compare {
  if (($# != 2)); then
    terminator::logger::error "invalid number of arguments" "usage: ${FUNCNAME[0]} rhs lhs"
    return 4
  fi

  awk -v lhs="$1" -v rhs="$2" 'BEGIN {
    if (lhs == rhs) {
      exit 0
    } else if (lhs > rhs) {
      exit 1
    } else if (lhs < rhs) {
      exit 2
    }
    exit 3
  }'
}

function terminator::number::is_integer {
  if (($# < 1)); then
    terminator::logger::error "invalid # of args: expected at least 1 argument" "Usage: ${FUNCNAME[0]} value ... value"
    return 1
  fi

  local value

  for value in "$@"; do
    if [[ ! "${value}" =~ ^[-+]?[0-9]+$ ]]; then
      return 1
    fi
  done
}

function terminator::number::is_unsigned_integer {
  if (($# < 1)); then
    terminator::logger::error "invalid # of args: expected at least 1 argument" "Usage: ${FUNCNAME[0]} value ... value"
    return 1
  fi

  local value

  for value in "$@"; do
    if [[ ! "${value}" =~ ^[+]?[0-9]+$ ]]; then
      return 1
    fi
  done
}

function terminator::number::__export__ {
  export -f terminator::number::compare
  export -f terminator::number::is_integer
  export -f terminator::number::is_unsigned_integer
}

# KCOV_EXCL_START
function terminator::number::__recall__ {
  export -fn terminator::number::compare
  export -fn terminator::number::is_integer
  export -fn terminator::number::is_unsigned_integer
}
# KCOV_EXCL_STOP

terminator::__module__::export
