#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::pipx::__initialize__() {
  local local_bin_path="${HOME}/.local/bin"

  if [[ ! -d "${local_bin_path}" ]]; then
    terminator::log::warning "${local_bin_path} does not exist"
    return
  fi

  if [[ ! -x "${local_bin_path}/pipx" ]]; then
    terminator::log::warning "${local_bin_path}/pipx does not exist"
    return
  fi

  terminator::path::append "${local_bin_path}"
}
