#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"
source "${HOME}/.terminator/src/path.sh"

function terminator::os::darwin::finder::show_hidden_files() {
  terminator::os::darwin::finder::set_show_all_files 'YES'
}

function terminator::os::darwin::finder::hide_hidden_files() {
  terminator::os::darwin::finder::set_show_all_files 'NO'
}

function terminator::os::darwin::finder::set_show_all_files() {
  local value="${1:-NO}"
  defaults write com.apple.finder AppleShowAllFiles "${value}" \
    && killall Finder /System/Library/CoreServices/Finder.app
}
