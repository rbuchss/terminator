#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/config.sh"
source "${HOME}/.terminator/src/path.sh"

function terminator::bootstrap() {
  terminator::bootstrap::tmux

  # TODO convert this to .terminator/bin
  terminator::path::prepend \
    "${HOME}/bin-terminator" \
    "${HOME}/bin"

  terminator::cdpath::prepend \
    '/opt' \
    "${HOME}"

  terminator::bootstrap::os

  terminator::config::load \
    '.bash_styles' \
    '.bashrc' \
    '.bash_aliases'

  # TODO move this to src or bin
  terminator::source "${HOME}/.tmux/helpers/tmuxinator.bash"

  terminator::bootstrap::autoload
  terminator::bootstrap::pyenv
  terminator::bootstrap::rbenv
  terminator::bootstrap::jenv

  # ensure CDPATH has . as first element
  terminator::cdpath::prepend '.'

  terminator::log::debug \
    "Profile PATH: $PATH" \
    "Profile MANPATH: $MANPATH" \
    "Profile CDPATH: $CDPATH"
}

function terminator::bootstrap::tmux() {
  # prevents duplicated path created when using tmux
  # by clearing out the old path and then rebuilding it
  # like a brand new login shell
  # will not do this if bash_login has already been run
  if [[ -n "${TMUX}" ]] && [[ -z "${tmux_path_initialized}" ]]; then
    terminator::log::debug 'initializing tmux ...'
    terminator::paths::clear
    source /etc/profile
    # TODO change this to match style-guide
    export tmux_path_initialized=true
  fi
}

function terminator::bootstrap::os() {
  case "${OSTYPE}" in
    darwin*) terminator::bootstrap::os::darwin ;;
    linux*) terminator::bootstrap::os::linux ;;
    msys*) terminator::bootstrap::os::windows ;;
    *) terminator::bootstrap::os::unsupported ;;
  esac
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
  for autoload_file in "${HOME}"/.bash_autoload*; do
    terminator::source "${autoload_file}"
  done
}

function terminator::bootstrap::pyenv() {
  if command -v pyenv > /dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    source "$(brew --prefix pyenv)/completions/pyenv.bash"
  fi
}

function terminator::bootstrap::rbenv() {
  if command -v rbenv > /dev/null 2>&1; then
    eval "$(rbenv init -)" > /dev/null
    source "$(brew --prefix rbenv)/completions/rbenv.bash"
  fi
}

function terminator::bootstrap::jenv() {
  if command -v jenv > /dev/null 2>&1; then
    # export PATH="$HOME/.jenv/bin:$PATH"
    eval "$(jenv init -)"
  fi
}
