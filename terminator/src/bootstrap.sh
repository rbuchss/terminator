#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

function terminator::bootstrap() {
  terminator::bootstrap::tmux

  # MANPATH must be defined, even if empty
  # before /etc/profile -> path_helper runs
  # From the path_helper info page:
  #   The MANPATH environment variable will not be modified
  #   unless it is already set in the environment.
  terminator::manpath::prepend \
    '/usr/X11/share/man' \
    '/usr/local/share/man' \
    '/usr/share/man'

  source /etc/profile

  terminator::path::prepend \
    "${HOME}/.terminator/bin" \
    "${HOME}/bin"

  terminator::cdpath::prepend \
    '/opt' \
    "${HOME}"

  terminator::os::switch \
    --darwin terminator::bootstrap::os::darwin \
    --linux terminator::bootstrap::os::linux \
    --windows terminator::bootstrap::os::windows \
    --unsupported terminator::bootstrap::os::unsupported

  terminator::config::load \
    '.bash_opt' \
    '.bash_styles' \
    '.bashrc' \
    '.bash_aliases'

  terminator::bootstrap::autoload

  # ensure CDPATH has . as first element
  terminator::cdpath::prepend '.'

  terminator::log::debug \
    "Profile PATH: $PATH" \
    "Profile MANPATH: $MANPATH" \
    "Profile CDPATH: $CDPATH"
}

function terminator::bootstrap::tmux() {
  # prevents duplicated path/cdpath/manpath/PROMPT_COMMAND
  # created when using tmux
  # by clearing out the old path and then rebuilding it
  # like a brand new login shell
  # will not do this if bash_login has already been run
  if [[ -n "${TMUX}" ]] && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    terminator::log::debug 'initializing tmux ...'
    terminator::paths::clear
    PROMPT_COMMAND=''
    export TMUX_PATH_INITIALIZED=1
  fi

  terminator::source "${HOME}/.tmux/config/tmux.sh"
}

function terminator::bootstrap::os::darwin() {
  terminator::config::load 'os/darwin.sh'
}

function terminator::bootstrap::os::linux() {
  terminator::config::load 'os/linux.sh'
}

function terminator::bootstrap::os::windows() {
  terminator::config::load 'os/windows.sh'
}

function terminator::bootstrap::os::unsupported() {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::bootstrap::autoload() {
  if compgen -G "${HOME}/.bash_autoload*" > /dev/null 2>&1; then
    for autoload_file in "${HOME}"/.bash_autoload*; do
      terminator::source "${autoload_file}"
    done
  else
    terminator::log::debug 'skipping - no ~/.bash_autoload* files found'
  fi
}
