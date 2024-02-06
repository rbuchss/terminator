#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

function terminator::jetbrains::__enable__ {
  terminator::os::switch \
    --darwin terminator::jetbrains::__enable__::os::darwin \
    --linux terminator::jetbrains::__enable__::os::linux \
    --windows terminator::jetbrains::__enable__::os::windows \
    --unsupported terminator::jetbrains::__enable__::os::unsupported
}

function terminator::jetbrains::__disable__ {
  terminator::os::switch \
    --darwin terminator::jetbrains::__disable__::os::darwin \
    --linux terminator::jetbrains::__disable__::os::linux \
    --windows terminator::jetbrains::__disable__::os::windows \
    --unsupported terminator::jetbrains::__disable__::os::unsupported
}

function terminator::jetbrains::__enable__::os::darwin {
  terminator::path::append \
    "${HOME}/Library/Application Support/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__disable__::os::darwin {
  terminator::path::remove \
    "${HOME}/Library/Application Support/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__enable__::os::linux {
  terminator::path::append \
    "${HOME}/.local/share/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__disable__::os::linux {
  terminator::path::remove \
    "${HOME}/.local/share/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__enable__::os::windows {
  terminator::path::append \
    "${LOCALAPPDATA}/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__disable__::os::windows {
  terminator::path::remove \
    "${LOCALAPPDATA}/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__enable__::os::unsupported {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::jetbrains::__disable__::os::unsupported {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::jetbrains::__export__ {
  :
}

function terminator::jetbrains::__recall__ {
  :
}

terminator::__module__::export
