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
  # shellcheck disable=SC2119 # optional --force flag, no args needed here
  terminator::claude::mcp::add::context7
  # shellcheck disable=SC2119 # optional --force flag, no args needed here
  terminator::claude::mcp::add::serena

  terminator::claude::settings::merge_baseline
}

function terminator::claude::__disable__ {
  local local_bin_path="${HOME}/.local/bin"

  terminator::path::remove "${local_bin_path}"
}

# Guards against missing claude CLI. Logs a warning with the caller's name.
# Optional message argument appends context to the warning.
function terminator::claude::__require_claude__ {
  if terminator::command::exists claude; then
    return 0
  fi

  local msg="claude is not installed, skipping ${FUNCNAME[1]}"
  if [[ -n "$1" ]]; then
    msg+=": $1"
  fi

  terminator::logger::warning "${msg}"
  return 1
}

# shellcheck disable=SC2120 # optional --force flag, called without args by default
function terminator::claude::mcp::add::context7 {
  terminator::claude::__require_claude__ 'context7' || return 1

  local \
    force=0 \
    desired_version='2.1.2' \
    current_version

  while (($# > 0)); do
    case "$1" in
      -f | --force) force=1 ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  current_version="$(
    claude mcp list \
      | grep 'context7' \
      | grep -o '@upstash/context7-mcp@[0-9.]*' \
      | cut -d@ -f3
  )"

  if [[ -z "${current_version}" ]] \
    || [[ "${current_version}" != "${desired_version}" ]] \
    || ((force == 1)); then
    claude mcp remove --scope user context7 2>/dev/null || true
    claude mcp add \
      --scope user context7 \
      -- bunx -y @upstash/context7-mcp@${desired_version}
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
# shellcheck disable=SC2120 # optional --force flag, called without args by default
function terminator::claude::mcp::add::serena {
  terminator::claude::__require_claude__ 'serena' || return 1

  local \
    force=0 \
    desired_commit='2ab807a1ff13ffc08e82070e44c3d2bfc5aa75f8' \
    repo_url='https://github.com/oraios/serena' \
    current_commit

  while (($# > 0)); do
    case "$1" in
      -f | --force) force=1 ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  current_commit="$(
    claude mcp list \
      | grep 'serena' \
      | grep -o 'oraios/serena@[0-9a-f]*' \
      | cut -d@ -f2
  )"

  if [[ -z "${current_commit}" ]] \
    || [[ "${current_commit}" != "${desired_commit}" ]] \
    || ((force == 1)); then
    claude mcp remove --scope user serena 2>/dev/null || true
    claude mcp add \
      --scope user serena \
      -- uvx --from "git+${repo_url}@${desired_commit}" \
      serena start-mcp-server --context claude-code --project-from-cwd \
      --open-web-dashboard False
  fi
}

# Adds the mcp-atlassian MCP server (Jira + Confluence) at user scope.
# Requires JIRA_* and CONFLUENCE_* env vars to be set for authentication.
# Supports -f/--force to re-add even when the version matches, useful after
# rotating secrets.
# See: https://github.com/sooperset/mcp-atlassian
function terminator::claude::mcp::add::atlassian {
  terminator::claude::__require_claude__ 'mcp-atlassian' || return 1

  local missing=()

  [[ -z "${JIRA_URL}" ]] && missing+=('JIRA_URL')
  [[ -z "${JIRA_USERNAME}" ]] && missing+=('JIRA_USERNAME')
  [[ -z "${JIRA_API_TOKEN}" ]] && missing+=('JIRA_API_TOKEN')
  [[ -z "${CONFLUENCE_URL}" ]] && missing+=('CONFLUENCE_URL')
  [[ -z "${CONFLUENCE_USERNAME}" ]] && missing+=('CONFLUENCE_USERNAME')
  [[ -z "${CONFLUENCE_API_TOKEN}" ]] && missing+=('CONFLUENCE_API_TOKEN')

  if ((${#missing[@]} > 0)); then
    terminator::logger::warning \
      "mcp-atlassian: missing env vars: ${missing[*]}"
    return 1
  fi

  local \
    force=0 \
    desired_version='0.21.0' \
    current_version

  while (($# > 0)); do
    case "$1" in
      -f | --force) force=1 ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  current_version="$(
    claude mcp list \
      | grep 'atlassian' \
      | grep -o 'mcp-atlassian==[0-9.]*' \
      | cut -d= -f3
  )"

  if [[ -z "${current_version}" ]] \
    || [[ "${current_version}" != "${desired_version}" ]] \
    || ((force == 1)); then
    claude mcp remove --scope user atlassian 2>/dev/null || true
    claude mcp add \
      --scope user atlassian \
      -e JIRA_URL="${JIRA_URL}" \
      -e JIRA_USERNAME="${JIRA_USERNAME}" \
      -e JIRA_API_TOKEN="${JIRA_API_TOKEN}" \
      -e CONFLUENCE_URL="${CONFLUENCE_URL}" \
      -e CONFLUENCE_USERNAME="${CONFLUENCE_USERNAME}" \
      -e CONFLUENCE_API_TOKEN="${CONFLUENCE_API_TOKEN}" \
      -- uvx mcp-atlassian==${desired_version}
  fi
}

# Merges open-source baseline settings into ~/.claude/settings.json.
# Existing user settings take precedence (baseline provides defaults only).
# Handles transition from homesick-managed symlink to generated regular file.
function terminator::claude::settings::merge_baseline {
  local \
    baseline_path="${TERMINATOR_MODULE_ROOT_DIR}/config/claude/settings.base.json" \
    settings_path="${HOME}/.claude/settings.json" \
    merged \
    current

  if ! terminator::command::exists jq; then
    terminator::logger::warning 'jq is required for claude settings merge'
    return 1
  fi

  if [[ ! -f "${baseline_path}" ]]; then
    terminator::logger::warning "claude baseline settings not found: ${baseline_path}"
    return 1
  fi

  # Remove symlinks (broken or live) to decouple from homesick tracking.
  # Reads existing content through the symlink before removing it.
  if [[ -L "${settings_path}" ]]; then
    if [[ -f "${settings_path}" ]]; then
      current="$(cat "${settings_path}")"
    fi
    rm "${settings_path}"
    if [[ -n "${current}" ]]; then
      printf '%s\n' "${current}" >"${settings_path}"
    fi
  fi

  if [[ ! -f "${settings_path}" ]]; then
    mkdir -p "${HOME}/.claude"
    jq . "${baseline_path}" >"${settings_path}"
    return 0
  fi

  merged="$(jq -s '.[0] * .[1]' "${baseline_path}" "${settings_path}")"
  current="$(cat "${settings_path}")"

  if [[ "${merged}" == "${current}" ]]; then
    return 0
  fi

  printf '%s\n' "${merged}" >"${settings_path}.tmp"
  mv "${settings_path}.tmp" "${settings_path}"
}

# Checks if a marketplace repo is already registered.
# Matches the parenthesized repo format from `claude plugin marketplace list`.
function terminator::claude::plugin::marketplace::exists {
  local marketplace_repo="$1"

  terminator::claude::__require_claude__ || return 1

  claude plugin marketplace list 2>/dev/null \
    | grep -qF "(${marketplace_repo})"
}

# Registers a Claude Code plugin marketplace if not already present.
function terminator::claude::plugin::marketplace::add {
  local marketplace_repo="$1"

  terminator::claude::__require_claude__ || return 1

  if terminator::claude::plugin::marketplace::exists "${marketplace_repo}"; then
    return 0
  fi

  claude plugin marketplace add "${marketplace_repo}"
}

# Checks if a plugin is already installed.
# Matches the plugin ID format from `claude plugin list`.
function terminator::claude::plugin::exists {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  claude plugin list 2>/dev/null \
    | grep -qF "${plugin_id}"
}

# Checks if a plugin is enabled by looking for the enabled status marker
# in the output block following the plugin ID line.
function terminator::claude::plugin::is_enabled {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  claude plugin list 2>/dev/null \
    | grep -A3 -F "${plugin_id}" \
    | grep -qF 'enabled'
}

# Installs and enables a Claude Code plugin.
# Handles three states: not installed, installed but disabled, installed and enabled.
function terminator::claude::plugin::install {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  if terminator::claude::plugin::is_enabled "${plugin_id}"; then
    return 0
  fi

  if ! terminator::claude::plugin::exists "${plugin_id}"; then
    claude plugin install "${plugin_id}"
  fi

  claude plugin enable "${plugin_id}"
}

# Registers a Claude Code plugin marketplace and installs/enables the plugin.
# Usage: register --plugin PLUGIN_ID --marketplace GITHUB_REPO
function terminator::claude::plugin::register {
  local plugin_id marketplace_repo

  while (($# != 0)); do
    case "$1" in
      --plugin)
        shift
        plugin_id="$1"
        ;;
      --marketplace)
        shift
        marketplace_repo="$1"
        ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  terminator::claude::__require_claude__ "${plugin_id}" || return 1

  if [[ -z "${plugin_id}" ]]; then
    terminator::logger::warning '--plugin is required'
    return 1
  fi

  if [[ -z "${marketplace_repo}" ]]; then
    terminator::logger::warning '--marketplace is required'
    return 1
  fi

  terminator::claude::plugin::marketplace::add "${marketplace_repo}"
  terminator::claude::plugin::install "${plugin_id}"
}

function terminator::claude::__export__ {
  export -f terminator::claude::__require_claude__
  export -f terminator::claude::mcp::add::context7
  export -f terminator::claude::mcp::add::serena
  export -f terminator::claude::mcp::add::atlassian
  export -f terminator::claude::settings::merge_baseline
  export -f terminator::claude::plugin::marketplace::exists
  export -f terminator::claude::plugin::marketplace::add
  export -f terminator::claude::plugin::exists
  export -f terminator::claude::plugin::is_enabled
  export -f terminator::claude::plugin::install
  export -f terminator::claude::plugin::register
}

# KCOV_EXCL_START
function terminator::claude::__recall__ {
  export -fn terminator::claude::__require_claude__
  export -fn terminator::claude::mcp::add::context7
  export -fn terminator::claude::mcp::add::serena
  export -fn terminator::claude::mcp::add::atlassian
  export -fn terminator::claude::settings::merge_baseline
  export -fn terminator::claude::plugin::marketplace::exists
  export -fn terminator::claude::plugin::marketplace::add
  export -fn terminator::claude::plugin::exists
  export -fn terminator::claude::plugin::is_enabled
  export -fn terminator::claude::plugin::install
  export -fn terminator::claude::plugin::register
}
# KCOV_EXCL_STOP

terminator::__module__::export
