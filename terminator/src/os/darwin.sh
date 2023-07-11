#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*/*}/path.sh"
source "${BASH_SOURCE[0]%/*/*}/source.sh"

terminator::__pragma__::once || return 0

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
