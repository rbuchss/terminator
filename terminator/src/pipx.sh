#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::pipx::__enable__() {
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

function terminator::pipx::__export__() {
  :
}

function terminator::pipx::__recall__() {
  :
}

terminator::__module__::export
