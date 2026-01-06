#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/logger.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/path.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/source.sh"

terminator::__module__::load || return 0

function terminator::os::darwin::__enable__ {
  # Set default screenshots directory
  export TERMINATOR_SCREENSHOTS_DIR="${TERMINATOR_SCREENSHOTS_DIR:-${HOME}/Desktop/Screenshots}"

  alias show-files='terminator::os::darwin::finder::show_hidden_files'
  alias hide-files='terminator::os::darwin::finder::hide_hidden_files'
  alias set-screenshot-dir='terminator::os::darwin::screencapture::set_location'
}

function terminator::os::darwin::finder::show_hidden_files {
  terminator::os::darwin::finder::set_show_all_files 'YES'
}

function terminator::os::darwin::finder::hide_hidden_files {
  terminator::os::darwin::finder::set_show_all_files 'NO'
}

function terminator::os::darwin::finder::set_show_all_files {
  local value="${1:-NO}"
  defaults write com.apple.finder AppleShowAllFiles "${value}" &&
    killall Finder /System/Library/CoreServices/Finder.app
}

function terminator::os::darwin::screencapture::set_location {
  local location="${1:-${TERMINATOR_SCREENSHOTS_DIR}}"

  # Create directory if it doesn't exist
  if [[ ! -d "${location}" ]]; then
    mkdir -p "${location}"
  fi

  # Set the screenshot location
  defaults write com.apple.screencapture location "${location}" &&
    killall SystemUIServer

  terminator::logger::info "Screenshot location set to: ${location}"
}

function terminator::os::darwin::__export__ {
  export -f terminator::os::darwin::finder::show_hidden_files
  export -f terminator::os::darwin::finder::hide_hidden_files
  export -f terminator::os::darwin::finder::set_show_all_files
  export -f terminator::os::darwin::screencapture::set_location
}

function terminator::os::darwin::__recall__ {
  export -fn terminator::os::darwin::finder::show_hidden_files
  export -fn terminator::os::darwin::finder::hide_hidden_files
  export -fn terminator::os::darwin::finder::set_show_all_files
  export -fn terminator::os::darwin::screencapture::set_location
}

terminator::__module__::export
