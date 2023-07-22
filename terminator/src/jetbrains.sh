#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

function terminator::jetbrains::__initialize__() {
  terminator::os::switch \
    --darwin terminator::jetbrains::__initialize__::os::darwin \
    --linux terminator::jetbrains::__initialize__::os::linux \
    --windows terminator::jetbrains::__initialize__::os::windows \
    --unsupported terminator::jetbrains::__initialize__::os::unsupported
}

function terminator::jetbrains::__initialize__::os::darwin() {
  terminator::path::append \
    "${HOME}/Library/Application Support/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__initialize__::os::linux() {
  terminator::path::append \
    "${HOME}/.local/share/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__initialize__::os::windows() {
  terminator::path::append \
    "${LOCALAPPDATA}/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::__initialize__::os::unsupported() {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}
