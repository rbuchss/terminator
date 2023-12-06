#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*/*}/path.sh"
source "${BASH_SOURCE[0]%/*/*}/source.sh"

terminator::__module__::load || return 0

function terminator::os::darwin::__enable__() {
  alias show-files='terminator::os::darwin::finder::show_hidden_files'
  alias hide-files='terminator::os::darwin::finder::hide_hidden_files'
}

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

function terminator::os::darwin::__export__() {
  export -f terminator::os::darwin::finder::show_hidden_files
  export -f terminator::os::darwin::finder::hide_hidden_files
  export -f terminator::os::darwin::finder::set_show_all_files
}

function terminator::os::darwin::__recall__() {
  export -fn terminator::os::darwin::finder::show_hidden_files
  export -fn terminator::os::darwin::finder::hide_hidden_files
  export -fn terminator::os::darwin::finder::set_show_all_files
}

terminator::__module__::export
