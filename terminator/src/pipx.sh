#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

terminator::__module__::load || return 0

function terminator::pipx::__enable__ {
  local local_bin_path="${HOME}/.local/bin"

  if [[ ! -d "${local_bin_path}" ]]; then
    terminator::logger::warning "${local_bin_path} does not exist"
    return 1
  fi

  if ! terminator::command::exists pipx \
    && [[ ! -x "${local_bin_path}/pipx" ]]; then
    terminator::logger::warning 'pipx command does not exist'
    return 1
  fi

  terminator::path::append "${local_bin_path}"
}

function terminator::pipx::__disable__ {
  local local_bin_path="${HOME}/.local/bin"

  terminator::path::remove "${local_bin_path}"
}

function terminator::pipx::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::pipx::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
