#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"
source "${BASH_SOURCE[0]%/*}/source.sh"

terminator::__pragma__::once || return 0

function terminator::homebrew::is_installed() {
  command -v brew > /dev/null 2>&1
}

function terminator::homebrew::package::is_installed() {
  # NOTE: both of the recommended ways to tell if
  #   a package is installed are really slow... ~+0.5s
  #
  # brew list --full-name "$1" > /dev/null 2>&1
  # brew --prefix --installed "$1" > /dev/null 2>&1
  #
  terminator::homebrew::is_installed &&
    ls "$(brew --prefix "$1")" > /dev/null 2>&1
}

function terminator::homebrew::bootstrap() {
  local brew_path_exists=0 \
    possible_brew_paths=(/usr/local/bin/brew /opt/homebrew/bin/brew)

  for brew_path in "${possible_brew_paths[@]}"; do
    if [[ -x "${brew_path}" ]]; then
      eval "$("${brew_path}" shellenv)"
      brew_path_exists=1
      break
    fi
  done

  if (( brew_path_exists == 0 )); then
    terminator::log::warning "homebrew path is not found in possible paths: ${possible_brew_paths[*]}"
    return
  fi

  if terminator::homebrew::is_installed; then
    # using GNU for coreutils vs BSD
    terminator::homebrew::add_paths \
      'coreutils' \
      'gnu-sed' \
      'make'

    # If not running interactively, don't do anything
    if [[ -n "${PS1}" ]]; then
      terminator::homebrew::bootstrap::bash_completion

      alias brew-cleaner='terminator::homebrew::clean'
      alias brew-cask-cleaner='terminator::homebrew::cask::clean'
    fi
  else
    terminator::log::warning 'homebrew is not installed'
  fi
}

function terminator::homebrew::add_paths() {
  local prefix

  for element in "$@"; do
    if terminator::homebrew::package::is_installed "${element}"; then
      prefix="$(brew --prefix "${element}")"
      terminator::log::debug "'${prefix}'"
      terminator::path::prepend "${prefix}/libexec/gnubin"
      terminator::manpath::prepend "${prefix}/libexec/gnuman"
    else
      terminator::log::warning "homebrew package ${element} is not installed"
    fi
  done
}

function terminator::homebrew::clean() {
  brew update && brew cleanup
}

function terminator::homebrew::cask::clean() {
  brew upgrade brew-cask && brew cask cleanup
}

function terminator::homebrew::bootstrap::bash_completion() {
  if terminator::homebrew::package::is_installed bash-completion; then
    terminator::source "$(brew --prefix)/etc/bash_completion"
  else
    terminator::log::warning 'homebrew package bash-completion is not installed'
  fi
}
