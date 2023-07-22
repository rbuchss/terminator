#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::rust::__initialize__() {
  if ! command -v rustc > /dev/null 2>&1; then
    terminator::log::warning 'rustc is not installed'
    return
  fi

  terminator::path::prepend "${HOME}/.cargo/bin"
  # NOTE: to enable rustup completion use the following command:
  #   rustup completions bash > ${system_completion_path}

  # NOTE: This enables cargo completion and must be loaded after
  # cargo is added to the path
  # shellcheck source=/dev/null
  source "$(rustc --print sysroot)"/etc/bash_completion.d/cargo
}
