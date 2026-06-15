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

# Parses the options shared by every mcp::add function and writes the resolved
# force flag (0/1) and version override (empty when unset) to the two
# caller-provided variable names. Returns 1 on an unrecognized option so the
# caller can propagate the failure.
# Usage: terminator::claude::mcp::__parse_options__ FORCE_VAR VERSION_VAR "$@"
function terminator::claude::mcp::__parse_options__ {
  local \
    __force_var__="$1" \
    __version_var__="$2" \
    __force__=0 \
    __version__=''

  shift 2

  while (($# > 0)); do
    case "$1" in
      -f | --force) __force__=1 ;;
      --version)
        shift
        __version__="$1"
        ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  printf -v "${__force_var__}" '%s' "${__force__}"
  printf -v "${__version_var__}" '%s' "${__version__}"
}

# Reconciles a user-scope MCP server to a desired value. When the installed
# value already matches and force is unset, it is a no-op; otherwise the server
# is removed and re-added. Everything after the force flag is passed verbatim as
# the `claude mcp add` command (including its own `--` separator).
# Usage: terminator::claude::mcp::__sync__ NAME CURRENT DESIRED FORCE <add args...>
function terminator::claude::mcp::__sync__ {
  local \
    name="$1" \
    current="$2" \
    desired="$3" \
    force="$4"

  shift 4

  if [[ -n "${current}" ]] \
    && [[ "${current}" == "${desired}" ]] \
    && ((force == 0)); then
    return 0
  fi

  claude mcp remove --scope user "${name}" 2>/dev/null || true
  claude mcp add --scope user "${name}" "$@"
}

# shellcheck disable=SC2120 # optional flags, called without args by default
function terminator::claude::mcp::add::context7 {
  terminator::claude::__require_claude__ 'context7' || return 1

  local \
    force \
    version \
    desired_version='2.1.2' \
    current_version

  terminator::claude::mcp::__parse_options__ force version "$@" || return 1
  [[ -n "${version}" ]] && desired_version="${version}"

  current_version="$(
    claude mcp list \
      | grep 'context7' \
      | grep -o '@upstash/context7-mcp@[0-9.]*' \
      | cut -d@ -f3
  )"

  terminator::claude::mcp::__sync__ \
    context7 "${current_version}" "${desired_version}" "${force}" \
    -- bunx -y "@upstash/context7-mcp@${desired_version}"
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
# shellcheck disable=SC2120 # optional flags, called without args by default
function terminator::claude::mcp::add::serena {
  terminator::claude::__require_claude__ 'serena' || return 1

  local \
    force \
    version \
    desired_commit='2ab807a1ff13ffc08e82070e44c3d2bfc5aa75f8' \
    repo_url='https://github.com/oraios/serena' \
    current_commit

  terminator::claude::mcp::__parse_options__ force version "$@" || return 1
  [[ -n "${version}" ]] && desired_commit="${version}"

  current_commit="$(
    claude mcp list \
      | grep 'serena' \
      | grep -o 'oraios/serena@[0-9a-f]*' \
      | cut -d@ -f2
  )"

  terminator::claude::mcp::__sync__ \
    serena "${current_commit}" "${desired_commit}" "${force}" \
    -- uvx --from "git+${repo_url}@${desired_commit}" \
    serena start-mcp-server --context claude-code --project-from-cwd \
    --open-web-dashboard False
}

# Adds the mcp-atlassian MCP server (Jira + Confluence) at user scope.
# Requires JIRA_* and CONFLUENCE_* env vars to be set for authentication.
# Supports -f/--force to re-add even when the version matches, useful after
# rotating secrets, and --version to override the pinned default.
# See: https://github.com/sooperset/mcp-atlassian
# shellcheck disable=SC2120 # optional flags, called without args by default
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
    force \
    version \
    desired_version='0.21.1' \
    current_version

  terminator::claude::mcp::__parse_options__ force version "$@" || return 1
  [[ -n "${version}" ]] && desired_version="${version}"

  current_version="$(
    claude mcp list \
      | grep 'atlassian' \
      | grep -o 'mcp-atlassian==[0-9.]*' \
      | cut -d= -f3
  )"

  terminator::claude::mcp::__sync__ \
    atlassian "${current_version}" "${desired_version}" "${force}" \
    -e JIRA_URL="${JIRA_URL}" \
    -e JIRA_USERNAME="${JIRA_USERNAME}" \
    -e JIRA_API_TOKEN="${JIRA_API_TOKEN}" \
    -e CONFLUENCE_URL="${CONFLUENCE_URL}" \
    -e CONFLUENCE_USERNAME="${CONFLUENCE_USERNAME}" \
    -e CONFLUENCE_API_TOKEN="${CONFLUENCE_API_TOKEN}" \
    -- uvx "mcp-atlassian==${desired_version}"
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

# Prints the resolved version of an installed plugin (the `Version:` field from
# `claude plugin list`), or nothing when the plugin is not installed.
function terminator::claude::plugin::installed_version {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  claude plugin list 2>/dev/null \
    | grep -A3 -F "${plugin_id}" \
    | grep -m1 'Version:' \
    | awk '{print $2}'
}

# Prints the git commit SHA an installed plugin was built from, read from
# Claude Code's internal installed_plugins.json. Prints nothing when the file,
# jq, or the plugin entry is missing.
function terminator::claude::plugin::installed_commit {
  local \
    plugin_id="$1" \
    installed_path="${HOME}/.claude/plugins/installed_plugins.json"

  [[ -f "${installed_path}" ]] || return 0
  terminator::command::exists jq || return 0

  jq -r --arg id "${plugin_id}" \
    '.plugins[$id][0].gitCommitSha // empty' \
    "${installed_path}" 2>/dev/null
}

# Re-pins a marketplace to a git ref and reinstalls the plugin from it. Removing
# the marketplace first is required because re-adding is the only way to change
# the pinned ref of an already-registered marketplace.
# Usage: __pin_and_reinstall__ MARKETPLACE_REPO REF PLUGIN_ID
function terminator::claude::plugin::__pin_and_reinstall__ {
  local \
    marketplace_repo="$1" \
    ref="$2" \
    plugin_id="$3" \
    marketplace_name="${1##*/}"

  if terminator::claude::plugin::marketplace::exists "${marketplace_repo}"; then
    claude plugin marketplace remove "${marketplace_name}" 2>/dev/null || true
  fi
  claude plugin marketplace add "${marketplace_repo}#${ref}"
  claude plugin uninstall "${plugin_id}" 2>/dev/null || true
  claude plugin install "${plugin_id}"
  claude plugin enable "${plugin_id}"
}

# Reconciles an installed plugin to a desired version or git ref, auto-detecting
# the form of the desired value:
#
#   * A git-SHA-like value (7-40 hex chars) pins the marketplace to that commit
#     via the `repo#ref` source suffix and compares against the installed commit
#     SHA, reinstalling on drift. This is the reproducible, GitHub-Actions-style
#     pin and works fully for plugins that omit `version` (their resolved version
#     is the commit SHA).
#
#   * A git tag or branch (anything that is neither a SHA nor a bare semver, for
#     example `v3.1.2`) pins the marketplace to that ref. A v-prefixed semver tag
#     resolves to the plugin's `plugin.json` version (the ref without the leading
#     `v`), so the reconcile compares the installed version locally and skips work
#     without a network round trip; other refs cannot be compared and reinstall.
#
#   * A bare semver (for example `2.5.1`) has no git ref to pin to, so it tracks
#     whatever the marketplace currently publishes and pulls updates on drift. It
#     can only move toward the marketplace's current version, and warns when the
#     resolved version still differs after updating (for example a downgrade,
#     which requires a tag or SHA instead).
#
# Usage: sync PLUGIN_ID MARKETPLACE_REPO DESIRED FORCE
function terminator::claude::plugin::sync {
  local \
    plugin_id="$1" \
    marketplace_repo="$2" \
    desired="$3" \
    force="$4" \
    marketplace_name="${2##*/}" \
    current \
    expected

  terminator::claude::__require_claude__ "${plugin_id}" || return 1

  # Commit SHA: pin to the commit and compare the installed commit SHA.
  if [[ "${desired}" =~ ^[0-9a-f]{7,40}$ ]]; then
    current="$(terminator::claude::plugin::installed_commit "${plugin_id}")"

    if [[ -n "${current}" ]] \
      && [[ "${current}" == "${desired}"* ]] \
      && ((force == 0)); then
      return 0
    fi

    terminator::claude::plugin::__pin_and_reinstall__ \
      "${marketplace_repo}" "${desired}" "${plugin_id}"
    return
  fi

  # Bare semver: track the marketplace's published version and update on drift.
  if [[ "${desired}" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    current="$(terminator::claude::plugin::installed_version "${plugin_id}")"

    if [[ -n "${current}" ]] \
      && [[ "${current}" == "${desired}" ]] \
      && ((force == 0)); then
      return 0
    fi

    terminator::claude::plugin::marketplace::add "${marketplace_repo}"
    claude plugin marketplace update "${marketplace_name}" 2>/dev/null || true
    terminator::claude::plugin::install "${plugin_id}"
    claude plugin update "${plugin_id}" 2>/dev/null || true

    current="$(terminator::claude::plugin::installed_version "${plugin_id}")"
    if [[ -n "${current}" ]] && [[ "${current}" != "${desired}" ]]; then
      terminator::logger::warning \
        "${plugin_id}: pinned version ${desired} but marketplace resolved ${current}"
    fi
    return
  fi

  # Git tag or branch: pin the marketplace to the ref. A v-prefixed semver tag
  # maps to the plugin.json version without the leading `v`, enabling a local,
  # network-free idempotency check.
  if [[ "${desired}" =~ ^v([0-9]+(\.[0-9]+)+)$ ]]; then
    expected="${BASH_REMATCH[1]}"
    current="$(terminator::claude::plugin::installed_version "${plugin_id}")"

    if [[ -n "${current}" ]] \
      && [[ "${current}" == "${expected}" ]] \
      && ((force == 0)); then
      return 0
    fi
  fi

  terminator::claude::plugin::__pin_and_reinstall__ \
    "${marketplace_repo}" "${desired}" "${plugin_id}"
}

# Registers a Claude Code plugin marketplace and installs/enables the plugin.
# With --version, the plugin is reconciled to a pinned version or git ref on
# every call (see terminator::claude::plugin::sync); without it, the plugin is
# installed at whatever version the marketplace currently publishes.
# Usage: register --plugin PLUGIN_ID --marketplace GITHUB_REPO \
#          [--version VERSION_OR_SHA] [-f|--force]
function terminator::claude::plugin::register {
  local \
    plugin_id \
    marketplace_repo \
    version \
    force=0

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
      --version)
        shift
        version="$1"
        ;;
      -f | --force) force=1 ;;
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

  if [[ -n "${version}" ]]; then
    terminator::claude::plugin::sync \
      "${plugin_id}" "${marketplace_repo}" "${version}" "${force}"
    return
  fi

  terminator::claude::plugin::marketplace::add "${marketplace_repo}"
  terminator::claude::plugin::install "${plugin_id}"
}

function terminator::claude::__export__ {
  export -f terminator::claude::__require_claude__
  export -f terminator::claude::mcp::__parse_options__
  export -f terminator::claude::mcp::__sync__
  export -f terminator::claude::mcp::add::context7
  export -f terminator::claude::mcp::add::serena
  export -f terminator::claude::mcp::add::atlassian
  export -f terminator::claude::settings::merge_baseline
  export -f terminator::claude::plugin::marketplace::exists
  export -f terminator::claude::plugin::marketplace::add
  export -f terminator::claude::plugin::exists
  export -f terminator::claude::plugin::is_enabled
  export -f terminator::claude::plugin::install
  export -f terminator::claude::plugin::installed_version
  export -f terminator::claude::plugin::installed_commit
  export -f terminator::claude::plugin::__pin_and_reinstall__
  export -f terminator::claude::plugin::sync
  export -f terminator::claude::plugin::register
}

# KCOV_EXCL_START
function terminator::claude::__recall__ {
  export -fn terminator::claude::__require_claude__
  export -fn terminator::claude::mcp::__parse_options__
  export -fn terminator::claude::mcp::__sync__
  export -fn terminator::claude::mcp::add::context7
  export -fn terminator::claude::mcp::add::serena
  export -fn terminator::claude::mcp::add::atlassian
  export -fn terminator::claude::settings::merge_baseline
  export -fn terminator::claude::plugin::marketplace::exists
  export -fn terminator::claude::plugin::marketplace::add
  export -fn terminator::claude::plugin::exists
  export -fn terminator::claude::plugin::is_enabled
  export -fn terminator::claude::plugin::install
  export -fn terminator::claude::plugin::installed_version
  export -fn terminator::claude::plugin::installed_commit
  export -fn terminator::claude::plugin::__pin_and_reinstall__
  export -fn terminator::claude::plugin::sync
  export -fn terminator::claude::plugin::register
}
# KCOV_EXCL_STOP

terminator::__module__::export
