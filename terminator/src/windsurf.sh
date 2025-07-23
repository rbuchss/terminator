#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

function terminator::windsurf::__enable__ {
  terminator::os::switch \
    --darwin terminator::windsurf::__enable__::os::darwin \
    --linux terminator::windsurf::__enable__::os::linux \
    --windows terminator::windsurf::__enable__::os::windows \
    --unsupported terminator::windsurf::__enable__::os::unsupported
}

function terminator::windsurf::__disable__ {
  terminator::os::switch \
    --darwin terminator::windsurf::__disable__::os::darwin \
    --linux terminator::windsurf::__disable__::os::linux \
    --windows terminator::windsurf::__disable__::os::windows \
    --unsupported terminator::windsurf::__disable__::os::unsupported
}

function terminator::windsurf::__enable__::os::darwin {
  terminator::path::append \
    "${HOME}/.codeium/windsurf/bin"
}

function terminator::windsurf::__disable__::os::darwin {
  terminator::path::remove \
    "${HOME}/.codeium/windsurf/bin"
}

function terminator::windsurf::__enable__::os::linux {
  # TODO: enable this for linux if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  # terminator::path::append \
  #   "${HOME}/.local/share/windsurf/scripts"
  terminator::windsurf::__enable__::os::unsupported
}

function terminator::windsurf::__disable__::os::linux {
  # TODO: enable this for linux if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  # terminator::path::remove \
  #   "${HOME}/.local/share/windsurf/scripts"
  terminator::windsurf::__disable__::os::unsupported
}

function terminator::windsurf::__enable__::os::windows {
  # TODO: enable this for windows if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  # terminator::path::append \
  #   "${LOCALAPPDATA}/windsurf/scripts"
  terminator::windsurf::__enable__::os::unsupported
}

function terminator::windsurf::__disable__::os::windows {
  # TODO: enable this for windows if possible.
  # For now setting this as unsupported until cli install path is confirmed.
  # terminator::path::remove \
  #   "${LOCALAPPDATA}/windsurf/scripts"
  terminator::windsurf::__disable__::os::unsupported
}

function terminator::windsurf::__enable__::os::unsupported {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::windsurf::__disable__::os::unsupported {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::windsurf::__export__ {
  :
}

function terminator::windsurf::__recall__ {
  :
}

terminator::__module__::export
