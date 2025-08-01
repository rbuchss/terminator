#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

terminator::__module__::load || return 0

function terminator::profile::load {
  terminator::config::hooks::before

  # MANPATH must be defined, even if empty
  # before /etc/profile -> path_helper runs
  # From the path_helper info page:
  #   The MANPATH environment variable will not be modified
  #   unless it is already set in the environment.
  terminator::manpath::prepend \
    '/usr/X11/share/man' \
    '/usr/local/share/man' \
    '/usr/share/man'

  terminator::source /etc/profile

  terminator::path::prepend \
    "${HOME}/.terminator/bin" \
    "${HOME}/bin"

  terminator::cdpath::prepend \
    '/opt' \
    "${HOME}"

  terminator::os::switch \
    --darwin terminator::profile::os::darwin \
    --linux terminator::profile::os::linux \
    --windows terminator::profile::os::windows \
    --unsupported terminator::profile::os::unsupported

  terminator::config::load \
    "__modules__.sh" \
    "${HOME}/.bashrc"

  terminator::config::hooks::after

  # ensure CDPATH has . as first element
  terminator::cdpath::prepend '.'

  terminator::logger::debug \
    "Profile PATH: ${PATH}" \
    "Profile MANPATH: ${MANPATH}" \
    "Profile CDPATH: ${CDPATH}"
}

function terminator::profile::os::darwin {
  terminator::config::load 'os/darwin.sh'
}

function terminator::profile::os::linux {
  terminator::config::load 'os/linux.sh'
}

function terminator::profile::os::windows {
  terminator::config::load 'os/windows.sh'
}

function terminator::profile::os::unsupported {
  terminator::logger::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::profile::__export__ {
  export -f terminator::profile::load
  export -f terminator::profile::os::darwin
  export -f terminator::profile::os::linux
  export -f terminator::profile::os::windows
  export -f terminator::profile::os::unsupported
}

function terminator::profile::__recall__ {
  export -fn terminator::profile::load
  export -fn terminator::profile::os::darwin
  export -fn terminator::profile::os::linux
  export -fn terminator::profile::os::windows
  export -fn terminator::profile::os::unsupported
}

terminator::__module__::export
