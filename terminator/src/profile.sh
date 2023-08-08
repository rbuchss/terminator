#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

terminator::__pragma__::once || return 0

function terminator::profile::__initialize__() {
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
    "modules.sh" \
    "styles.sh" \
    "${HOME}/.bashrc" \
    "aliases.sh"

  terminator::config::hooks::after

  # ensure CDPATH has . as first element
  terminator::cdpath::prepend '.'

  terminator::log::debug \
    "Profile PATH: ${PATH}" \
    "Profile MANPATH: ${MANPATH}" \
    "Profile CDPATH: ${CDPATH}"
}

function terminator::profile::os::darwin() {
  terminator::config::load 'os/darwin.sh'
}

function terminator::profile::os::linux() {
  terminator::config::load 'os/linux.sh'
}

function terminator::profile::os::windows() {
  terminator::config::load 'os/windows.sh'
}

function terminator::profile::os::unsupported() {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}
