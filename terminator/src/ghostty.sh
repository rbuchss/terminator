#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/os.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

function terminator::ghostty::__enable__ {
  terminator::os::switch \
    --darwin terminator::ghostty::__enable__::os::darwin \
    --linux terminator::ghostty::__enable__::os::linux \
    --windows terminator::ghostty::__enable__::os::windows \
    --unsupported terminator::ghostty::__enable__::os::unsupported
}

function terminator::ghostty::__disable__ {
  terminator::os::switch \
    --darwin terminator::ghostty::__disable__::os::darwin \
    --linux terminator::ghostty::__disable__::os::linux \
    --windows terminator::ghostty::__disable__::os::windows \
    --unsupported terminator::ghostty::__disable__::os::unsupported
}

function terminator::ghostty::__enable__::os::darwin {
  [[ -d '/Applications/Ghostty.app' ]] || return 0
  terminator::path::append '/Applications/Ghostty.app/Contents/MacOS'
}

function terminator::ghostty::__disable__::os::darwin {
  [[ -d '/Applications/Ghostty.app' ]] || return 0
  terminator::path::remove '/Applications/Ghostty.app/Contents/MacOS'
}

function terminator::ghostty::__enable__::os::linux {
  # TODO: enable this for linux if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  terminator::ghostty::__enable__::os::unsupported
}

function terminator::ghostty::__disable__::os::linux {
  # TODO: enable this for linux if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  terminator::ghostty::__disable__::os::unsupported
}

function terminator::ghostty::__enable__::os::windows {
  # TODO: enable this for linux if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  terminator::ghostty::__enable__::os::unsupported
}

function terminator::ghostty::__disable__::os::windows {
  # TODO: enable this for linux if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  terminator::ghostty::__disable__::os::unsupported
}

function terminator::ghostty::__enable__::os::unsupported {
  terminator::logger::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::ghostty::__disable__::os::unsupported {
  terminator::logger::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::ghostty::__export__ {
  :
}

function terminator::ghostty::__recall__ {
  :
}

terminator::__module__::export
