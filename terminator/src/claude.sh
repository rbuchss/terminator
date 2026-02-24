#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

terminator::__module__::load || return 0

function terminator::claude::__enable__ {
  local local_bin_path="${HOME}/.local/bin"

  if [[ ! -d "${local_bin_path}" ]]; then
    terminator::logger::warning "${local_bin_path} does not exist"
    return 1
  fi

  if ! terminator::command::exists claude \
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
  terminator::claude::mcp::add::serena
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
    || [[ "${current_version}" != "${desired_version}" ]]; then
    claude mcp remove --scope user context7 2>/dev/null || true
    claude mcp add \
      --scope user context7 \
      -- npx -y @upstash/context7-mcp@${desired_version}
  fi
}

# Pinned to a git commit instead of a PyPI version because the latest PyPI
# release (serena-agent 0.1.4) does not include the claude-code context, which
# disables tools that duplicate Claude Code's built-in capabilities. The
# claude-code context and --project-from-cwd flag are only available on main.
#
# LSP support is built-in. Serena bundles or auto-downloads language servers
# for most common languages (Python, JS/TS, Bash, Java) with no extra config.
# Some languages require external tooling: Go (gopls), Rust (rustup/
# rust-analyzer), C/C++ (clangd or ccls). The default --language-backend LSP
# is used unless overridden.
#
# Per-project language and ignore rules can be configured via
# .serena/project.yml in each repository. Global settings (language backend,
# UI, tool defaults, logging) live in the auto-created
# ~/.serena/serena_config.yml; CLI flags override it.
function terminator::claude::mcp::add::serena {
  local \
    desired_commit='2ab807a1ff13ffc08e82070e44c3d2bfc5aa75f8' \
    repo_url='https://github.com/oraios/serena' \
    current_commit

  current_commit="$(
    claude mcp list \
      | grep 'serena' \
      | grep -o 'oraios/serena@[0-9a-f]*' \
      | cut -d@ -f2
  )"

  if [[ -z "${current_commit}" ]] \
    || [[ "${current_commit}" != "${desired_commit}" ]]; then
    claude mcp remove --scope user serena 2>/dev/null || true
    claude mcp add \
      --scope user serena \
      -- uvx --from "git+${repo_url}@${desired_commit}" \
      serena start-mcp-server --context claude-code --project-from-cwd \
      --open-web-dashboard False
  fi
}

function terminator::claude::__export__ {
  export -f terminator::claude::mcp::add::context7
  export -f terminator::claude::mcp::add::serena
}

# KCOV_EXCL_START
function terminator::claude::__recall__ {
  export -fn terminator::claude::mcp::add::context7
  export -fn terminator::claude::mcp::add::serena
}
# KCOV_EXCL_STOP

terminator::__module__::export
