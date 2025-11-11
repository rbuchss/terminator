#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

terminator::__module__::load || return 0

function terminator::claude::__enable__ {
  local local_bin_path="${HOME}/.local/bin"

  if [[ ! -d "${local_bin_path}" ]]; then
    terminator::logger::warning "${local_bin_path} does not exist"
    return 1
  fi

  if ! command -v claude > /dev/null 2>&1 \
    && [[ ! -x "${local_bin_path}/claude" ]]; then
      terminator::logger::warning 'claude command does not exist'
      return 1
  fi

  terminator::path::append "${local_bin_path}"

  # Note that claude mcp does not support a .mcp.json file for user level scope.
  # So we need to use the cli command here to add any mcp servers at a user
  # level.
  #
  # See: https://code.claude.com/docs/en/mcp#project-scope
  #
  terminator::claude::mcp::add::context7
}

function terminator::claude::__disable__ {
  local local_bin_path="${HOME}/.local/bin"

  terminator::path::remove "${local_bin_path}"
}

function terminator::claude::mcp::add::context7 {
  local \
    desired_version='1.0.26' \
    current_version

  current_version="$(
    claude mcp list \
      | grep 'context7' \
      | grep -o '@upstash/context7-mcp@[0-9.]*' \
      | cut -d@ -f3
  )"

  if [[ -z "${current_version}" ]] \
    || [[ "${current_version}" != "${desired_version}" ]]
  then
    claude mcp remove --scope user context7 2>/dev/null || true
    claude mcp add \
      --scope user context7 \
      -- npx -y @upstash/context7-mcp@${desired_version}
  fi
}

function terminator::claude::__export__ {
  :
}

function terminator::claude::__recall__ {
  :
}

terminator::__module__::export
