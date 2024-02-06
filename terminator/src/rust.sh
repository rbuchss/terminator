#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::rust::__enable__ {
  terminator::command::exists -v rustc || return

  terminator::path::prepend "${HOME}/.cargo/bin"
  # NOTE: to enable rustup completion use the following command:
  #   rustup completions bash > ${system_completion_path}

  # NOTE: This enables cargo completion and must be loaded after
  # cargo is added to the path
  # shellcheck source=/dev/null
  source "$(rustc --print sysroot)"/etc/bash_completion.d/cargo
}

# TODO add support for this
# function terminator::rust::__disable__ {
#   terminator::path::remove "${HOME}/.cargo/bin"
#   # remove completions here...
# }

function terminator::rust::__export__ {
  :
}

function terminator::rust::__recall__ {
  :
}

terminator::__module__::export
