#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

function terminator::jetbrains::bootstrap() {
  terminator::os::switch \
    --darwin terminator::jetbrains::bootstrap::os::darwin \
    --linux terminator::jetbrains::bootstrap::os::linux \
    --windows terminator::jetbrains::bootstrap::os::windows \
    --unsupported terminator::jetbrains::bootstrap::os::unsupported
}

function terminator::jetbrains::bootstrap::os::darwin() {
  terminator::path::append \
    "${HOME}/Library/Application Support/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::bootstrap::os::linux() {
  terminator::path::append \
    "${HOME}/.local/share/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::bootstrap::os::windows() {
  terminator::path::append \
    "${LOCALAPPDATA}/JetBrains/Toolbox/scripts"
}

function terminator::jetbrains::bootstrap::os::unsupported() {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}
