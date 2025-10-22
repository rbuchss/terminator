#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

terminator::__module__::load || return 0

function terminator::diff::__enable__ {
  alias diffs='diff -y --suppress-common-lines'
}

function terminator::diff::__disable__ {
  unalias diffs
}

function terminator::diff::__export__ {
  :
}

function terminator::diff::__recall__ {
  :
}

terminator::__module__::export
