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
  terminator::claude::mcp::enable::context7

  # Serena is opt-in per repo or worktree. It is removed from user scope here
  # so machines running an older terminator self-migrate to the default-off
  # state; opt back in with terminator::claude::mcp::enable::serena.
  terminator::claude::mcp::__remove__ serena user

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

# Parses the options shared by every mcp enable helper and writes the resolved
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

# Parses the options shared by the scope-aware mcp enable helpers. In addition
# to the force and version flags handled by terminator::claude::mcp::__parse_options__,
# strips --project, which selects project scope (.mcp.json in the repo root)
# instead of the helper's default scope. Writes the resolved force flag (0/1),
# version override (empty when unset), and scope to the three caller-provided
# variable names. Returns 1 on an unrecognized option so the caller can
# propagate the failure.
# Usage: terminator::claude::mcp::__parse_scope_options__ FORCE_VAR VERSION_VAR SCOPE_VAR DEFAULT_SCOPE "$@"
function terminator::claude::mcp::__parse_scope_options__ {
  local \
    __force_var__="$1" \
    __version_var__="$2" \
    __scope_var__="$3" \
    __scope__="$4" \
    rest=()

  shift 4

  while (($# > 0)); do
    case "$1" in
      --project) __scope__='project' ;;
      *)
        rest+=("$1")
        ;;
    esac
    shift
  done

  terminator::claude::mcp::__parse_options__ \
    "${__force_var__}" "${__version_var__}" "${rest[@]+${rest[@]}}" \
    || return 1

  printf -v "${__scope_var__}" '%s' "${__scope__}"
}

# Parses the single scope flag accepted by the mcp disable helpers and writes
# the resolved scope to the caller-provided variable name. The default is the
# disable counterpart of the matching enable helper's default scope. Returns 1
# on any other option, since force and version have no meaning for a removal.
# Usage: terminator::claude::mcp::__parse_scope_flag__ SCOPE_VAR DEFAULT_SCOPE "$@"
function terminator::claude::mcp::__parse_scope_flag__ {
  local \
    __scope_var__="$1" \
    __scope__="$2"

  shift 2

  while (($# > 0)); do
    case "$1" in
      --project) __scope__='project' ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  printf -v "${__scope_var__}" '%s' "${__scope__}"
}

# Removes an MCP server registration at a scope. Succeeds when the server is
# absent, so callers can use it for idempotent cleanup.
# Usage: terminator::claude::mcp::__remove__ NAME SCOPE
function terminator::claude::mcp::__remove__ {
  terminator::claude::__require_claude__ "$1" || return 1

  claude mcp remove --scope "$2" "$1" 2>/dev/null || true
}

# Prints the git worktree root of the current directory, so scope-aware mcp
# helpers key their entries by worktree instead of by subdirectory. Local
# scope falls back to the current directory outside a repo; project scope has
# no repo root to write .mcp.json to, so it warns and fails instead.
# Usage: terminator::claude::mcp::__project_root__ SCOPE
function terminator::claude::mcp::__project_root__ {
  local \
    scope="$1" \
    root

  if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "${root}"
    return 0
  fi

  if [[ "${scope}" == 'local' ]]; then
    printf '%s\n' "${PWD}"
    return 0
  fi

  terminator::logger::warning \
    'not inside a git repo; nowhere to write project scope .mcp.json'
  return 1
}

# Reconciles an MCP server at a scope to a desired value. When the installed
# value already matches and force is unset, it is a no-op; otherwise the server
# is removed and re-added. Everything after the scope is passed verbatim as
# the `claude mcp add` command (including its own `--` separator).
# Usage: terminator::claude::mcp::__sync__ NAME CURRENT DESIRED FORCE SCOPE <add args...>
function terminator::claude::mcp::__sync__ {
  local \
    name="$1" \
    current="$2" \
    desired="$3" \
    force="$4" \
    scope="$5"

  shift 5

  if [[ -n "${current}" ]] \
    && [[ "${current}" == "${desired}" ]] \
    && ((force == 0)); then
    return 0
  fi

  terminator::claude::mcp::__remove__ "${name}" "${scope}"
  claude mcp add --scope "${scope}" "${name}" "$@"
}

# Context7 serves up-to-date library docs. It is enabled at user scope by
# default, the global registration that terminator::claude::__enable__
# auto-adds on every machine. --project writes .mcp.json at the repo root
# instead, for per-repo opt-in.
# shellcheck disable=SC2120 # optional flags, called without args by default
function terminator::claude::mcp::enable::context7 {
  terminator::claude::__require_claude__ 'context7' || return 1

  local \
    force \
    version \
    scope \
    root \
    desired_version='4.4.4' \
    current_version

  terminator::claude::mcp::__parse_scope_options__ force version scope user "$@" \
    || return 1
  [[ -n "${version}" ]] && desired_version="${version}"

  if ! root="$(terminator::claude::mcp::__project_root__ "${scope}")"; then
    return 1
  fi

  current_version="$(
    cd "${root}" \
      && claude mcp list \
      | grep 'context7' \
        | grep -o '@upstash/context7-mcp@[0-9.]*' \
        | cut -d@ -f3
  )"

  (
    cd "${root}" || exit 1
    terminator::claude::mcp::__sync__ \
      context7 "${current_version}" "${desired_version}" "${force}" "${scope}" \
      -- bunx -y "@upstash/context7-mcp@${desired_version}"
  )
}

# Removes the context7 registration added by
# terminator::claude::mcp::enable::context7. User scope (the default) removes
# the global entry; --project removes the repo's .mcp.json entry instead. Only
# the selected scope is touched.
# shellcheck disable=SC2120 # optional --project flag, no args needed by default
function terminator::claude::mcp::disable::context7 {
  terminator::claude::__require_claude__ 'context7' || return 1

  local \
    scope \
    root

  terminator::claude::mcp::__parse_scope_flag__ scope user "$@" || return 1

  if ! root="$(terminator::claude::mcp::__project_root__ "${scope}")"; then
    return 1
  fi

  (
    cd "${root}" || exit 1
    terminator::claude::mcp::__remove__ context7 "${scope}"
  )
}

# The claude-code context disables Serena tools that duplicate Claude
# Code's built-in capabilities, and --project-from-cwd scopes the server
# to the current project. Serena is GPL-3.0-or-later.
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
#
# Serena is opt-in per repo or worktree. It defaults to local scope: a private
# entry stored per project path in ~/.claude.json, so each git worktree is its
# own opt-in. --project writes .mcp.json at the repo root instead, shared
# with other worktrees when committed. Any user-scope registration is removed
# first so its version cannot mask the opted-in scope during detection.
# shellcheck disable=SC2120 # optional flags, called without args by default
function terminator::claude::mcp::enable::serena {
  terminator::claude::__require_claude__ 'serena' || return 1

  local \
    force \
    version \
    scope \
    root \
    desired_version='2.1.0' \
    current_version

  terminator::claude::mcp::__parse_scope_options__ force version scope local "$@" \
    || return 1
  [[ -n "${version}" ]] && desired_version="${version}"

  if ! root="$(terminator::claude::mcp::__project_root__ "${scope}")"; then
    return 1
  fi

  terminator::claude::mcp::__remove__ serena user

  current_version="$(
    cd "${root}" \
      && claude mcp list \
      | grep 'serena' \
        | grep -o 'serena-agent==[0-9.]*' \
        | cut -d= -f3
  )"

  (
    cd "${root}" || exit 1
    terminator::claude::mcp::__sync__ \
      serena "${current_version}" "${desired_version}" "${force}" "${scope}" \
      -- uvx --from "serena-agent==${desired_version}" \
      serena start-mcp-server --context claude-code --project-from-cwd \
      --open-web-dashboard False
  )
}

# Removes the opt-in Serena registration added by
# terminator::claude::mcp::enable::serena. Local scope (the default) removes
# the private entry for this worktree; --project removes the repo's .mcp.json
# entry instead. Only the selected scope is touched; user-scope cleanup is
# owned by terminator::claude::__enable__.
# shellcheck disable=SC2120 # optional --project flag, no args needed by default
function terminator::claude::mcp::disable::serena {
  terminator::claude::__require_claude__ 'serena' || return 1

  local \
    scope \
    root

  terminator::claude::mcp::__parse_scope_flag__ scope local "$@" || return 1

  if ! root="$(terminator::claude::mcp::__project_root__ "${scope}")"; then
    return 1
  fi

  (
    cd "${root}" || exit 1
    terminator::claude::mcp::__remove__ serena "${scope}"
  )
}

# Adds the mcp-atlassian MCP server (Jira + Confluence). Enabled at user
# scope by default; --project writes .mcp.json at the repo root instead, for
# per-repo opt-in. Requires JIRA_* and CONFLUENCE_* env vars to be set for
# authentication. Supports -f/--force to re-add even when the version matches,
# useful after rotating secrets, and --version to override the pinned default.
# See: https://github.com/sooperset/mcp-atlassian
# shellcheck disable=SC2120 # optional flags, called without args by default
function terminator::claude::mcp::enable::atlassian {
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
    scope \
    root \
    desired_version='0.23.1' \
    current_version

  terminator::claude::mcp::__parse_scope_options__ force version scope user "$@" \
    || return 1
  [[ -n "${version}" ]] && desired_version="${version}"

  if ! root="$(terminator::claude::mcp::__project_root__ "${scope}")"; then
    return 1
  fi

  current_version="$(
    cd "${root}" \
      && claude mcp list \
      | grep 'atlassian' \
        | grep -o 'mcp-atlassian==[0-9.]*' \
        | cut -d= -f3
  )"

  (
    cd "${root}" || exit 1
    terminator::claude::mcp::__sync__ \
      atlassian "${current_version}" "${desired_version}" "${force}" "${scope}" \
      -e JIRA_URL="${JIRA_URL}" \
      -e JIRA_USERNAME="${JIRA_USERNAME}" \
      -e JIRA_API_TOKEN="${JIRA_API_TOKEN}" \
      -e CONFLUENCE_URL="${CONFLUENCE_URL}" \
      -e CONFLUENCE_USERNAME="${CONFLUENCE_USERNAME}" \
      -e CONFLUENCE_API_TOKEN="${CONFLUENCE_API_TOKEN}" \
      -- uvx "mcp-atlassian==${desired_version}"
  )
}

# Removes the mcp-atlassian registration added by
# terminator::claude::mcp::enable::atlassian. User scope (the default) removes
# the global entry; --project removes the repo's .mcp.json entry instead. Only
# the selected scope is touched. No env vars are needed for a removal.
# shellcheck disable=SC2120 # optional --project flag, no args needed by default
function terminator::claude::mcp::disable::atlassian {
  terminator::claude::__require_claude__ 'mcp-atlassian' || return 1

  local \
    scope \
    root

  terminator::claude::mcp::__parse_scope_flag__ scope user "$@" || return 1

  if ! root="$(terminator::claude::mcp::__project_root__ "${scope}")"; then
    return 1
  fi

  (
    cd "${root}" || exit 1
    terminator::claude::mcp::__remove__ atlassian "${scope}"
  )
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

  # An empty settings file slurps as null, so merge it as {} and let the
  # baseline seed it. Invalid JSON fails the merge; the guard leaves the
  # file untouched instead of clobbering it with the empty result.
  if ! merged="$(jq -s '.[0] * (.[1] // {})' \
    "${baseline_path}" "${settings_path}" 2>/dev/null)"; then
    terminator::logger::warning \
      "claude settings merge failed; leaving ${settings_path} untouched"
    return 1
  fi

  current="$(cat "${settings_path}")"

  if [[ "${merged}" == "${current}" ]]; then
    return 0
  fi

  printf '%s\n' "${merged}" >"${settings_path}.tmp"
  mv "${settings_path}.tmp" "${settings_path}"
}

# Checks if a marketplace repo is already registered.
# Matches the repo field from `claude plugin marketplace list --json`, so a
# ref-pinned marketplace (shown as repo@ref) still matches its bare repo.
function terminator::claude::plugin::marketplace::exists {
  local marketplace_repo="$1"

  terminator::claude::__require_claude__ || return 1

  claude plugin marketplace list --json 2>/dev/null \
    | jq -e --arg repo "${marketplace_repo}" \
      '.[] | select(.repo == $repo)' >/dev/null 2>&1
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

# Prints a field for an installed plugin from `claude plugin list --json`, or
# nothing when the plugin is not installed or the field is absent. jq's `//`
# also drops false values, so boolean fields are read by comparing the output
# against 'true' rather than against 'false'.
# Usage: terminator::claude::plugin::__field__ PLUGIN_ID FIELD
function terminator::claude::plugin::__field__ {
  local \
    plugin_id="$1" \
    field="$2"

  terminator::claude::__require_claude__ || return 1

  claude plugin list --json 2>/dev/null \
    | jq -r --arg id "${plugin_id}" --arg field "${field}" \
      '.[] | select(.id == $id) | .[$field] // empty' 2>/dev/null
}

# Checks if a plugin is already installed.
# Matches the plugin by exact id against `claude plugin list --json`.
function terminator::claude::plugin::exists {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  terminator::claude::plugin::__field__ "${plugin_id}" id \
    | grep -q .
}

# Checks if a plugin is enabled by reading the enabled field from
# `claude plugin list --json`.
function terminator::claude::plugin::is_enabled {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  terminator::claude::plugin::__field__ "${plugin_id}" enabled \
    | grep -qx 'true'
}

# Disables an installed plugin when it is currently enabled, and does nothing
# when it is already disabled or not installed. Lets callers enforce a
# disabled end state without distinguishing the current one, mirroring the
# conditional-enable idiom used for the enabled end state.
# Usage: terminator::claude::plugin::__settle_disabled__ PLUGIN_ID
function terminator::claude::plugin::__settle_disabled__ {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  if ! terminator::claude::plugin::is_enabled "${plugin_id}"; then
    return 0
  fi

  claude plugin disable "${plugin_id}"
}

# Installs a Claude Code plugin and reconciles its enabled state.
# Handles three states: not installed, installed but disabled, installed and
# enabled. With a truthy DISABLED argument the reconcile targets a disabled
# end state instead: not installed installs then disables, installed and
# enabled just disables, and installed and disabled is a no-op.
# Usage: terminator::claude::plugin::install PLUGIN_ID [DISABLED]
function terminator::claude::plugin::install {
  local \
    plugin_id="$1" \
    disabled="${2:-0}"

  terminator::claude::__require_claude__ || return 1

  if ((disabled)); then
    if terminator::claude::plugin::exists "${plugin_id}"; then
      # Installed and already disabled: nothing to do.
      if ! terminator::claude::plugin::is_enabled "${plugin_id}"; then
        return 0
      fi
    else
      claude plugin install "${plugin_id}"
    fi

    # `claude plugin install` enables the plugin by default, so settle the
    # disabled end state (a no-op when the install left it disabled).
    terminator::claude::plugin::__settle_disabled__ "${plugin_id}"
    return
  fi

  if terminator::claude::plugin::is_enabled "${plugin_id}"; then
    return 0
  fi

  if ! terminator::claude::plugin::exists "${plugin_id}"; then
    claude plugin install "${plugin_id}"
  fi

  # `claude plugin install` enables the plugin by default, so only enable
  # explicitly when it is still disabled (avoids an "already enabled" error).
  terminator::claude::plugin::is_enabled "${plugin_id}" \
    || claude plugin enable "${plugin_id}"
}

# Prints the resolved version of an installed plugin (the version field from
# `claude plugin list --json`), or nothing when the plugin is not installed.
function terminator::claude::plugin::installed_version {
  local plugin_id="$1"

  terminator::claude::__require_claude__ || return 1

  terminator::claude::plugin::__field__ "${plugin_id}" version
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
# the pinned ref of an already-registered marketplace. A truthy DISABLED
# argument reconciles to a disabled end state instead of enabled.
# Usage: __pin_and_reinstall__ MARKETPLACE_REPO REF PLUGIN_ID [DISABLED]
function terminator::claude::plugin::__pin_and_reinstall__ {
  local \
    marketplace_repo="$1" \
    ref="$2" \
    plugin_id="$3" \
    marketplace_name="${1##*/}" \
    disabled="${4:-0}"

  if terminator::claude::plugin::marketplace::exists "${marketplace_repo}"; then
    claude plugin marketplace remove "${marketplace_name}" 2>/dev/null || true
  fi
  claude plugin marketplace add "${marketplace_repo}#${ref}"
  claude plugin uninstall "${plugin_id}" 2>/dev/null || true
  claude plugin install "${plugin_id}"

  # `claude plugin install` enables the plugin by default, so only enable
  # explicitly when it is still disabled (avoids an "already enabled" error);
  # a disabled reconcile instead disables it unless the install left it so.
  if ((disabled)); then
    terminator::claude::plugin::__settle_disabled__ "${plugin_id}"
  else
    terminator::claude::plugin::is_enabled "${plugin_id}" \
      || claude plugin enable "${plugin_id}"
  fi
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
# In every form, a truthy DISABLED argument reconciles to an installed-but-
# disabled end state instead of enabled: a version match that is currently
# enabled settles to disabled without a reinstall, and reinstalls leave the
# plugin disabled.
#
# Usage: sync PLUGIN_ID MARKETPLACE_REPO DESIRED FORCE [DISABLED]
function terminator::claude::plugin::sync {
  local \
    plugin_id="$1" \
    marketplace_repo="$2" \
    desired="$3" \
    force="$4" \
    disabled="${5:-0}" \
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
      if ((disabled)); then
        terminator::claude::plugin::__settle_disabled__ "${plugin_id}"
      fi
      return 0
    fi

    terminator::claude::plugin::__pin_and_reinstall__ \
      "${marketplace_repo}" "${desired}" "${plugin_id}" "${disabled}"
    return
  fi

  # Bare semver: track the marketplace's published version and update on drift.
  if [[ "${desired}" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    current="$(terminator::claude::plugin::installed_version "${plugin_id}")"

    if [[ -n "${current}" ]] \
      && [[ "${current}" == "${desired}" ]] \
      && ((force == 0)); then
      if ((disabled)); then
        terminator::claude::plugin::__settle_disabled__ "${plugin_id}"
      fi
      return 0
    fi

    terminator::claude::plugin::marketplace::add "${marketplace_repo}"
    claude plugin marketplace update "${marketplace_name}" 2>/dev/null || true
    terminator::claude::plugin::install "${plugin_id}" "${disabled}"
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
      if ((disabled)); then
        terminator::claude::plugin::__settle_disabled__ "${plugin_id}"
      fi
      return 0
    fi
  fi

  terminator::claude::plugin::__pin_and_reinstall__ \
    "${marketplace_repo}" "${desired}" "${plugin_id}" "${disabled}"
}

# Registers a Claude Code plugin marketplace and installs/enables the plugin.
# With --version, the plugin is reconciled to a pinned version or git ref on
# every call (see terminator::claude::plugin::sync); without it, the plugin is
# installed at whatever version the marketplace currently publishes. With
# --disabled, the plugin is reconciled to an installed-but-disabled state
# instead of enabled.
# Usage: register --plugin PLUGIN_ID --marketplace GITHUB_REPO \
#          [--version VERSION_OR_SHA] [--disabled] [-f|--force]
function terminator::claude::plugin::register {
  local \
    plugin_id \
    marketplace_repo \
    version \
    force=0 \
    disabled=0

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
      --disabled) disabled=1 ;;
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
      "${plugin_id}" "${marketplace_repo}" "${version}" "${force}" \
      "${disabled}"
    return
  fi

  terminator::claude::plugin::marketplace::add "${marketplace_repo}"
  terminator::claude::plugin::install "${plugin_id}" "${disabled}"
}

function terminator::claude::__export__ {
  export -f terminator::claude::__require_claude__
  export -f terminator::claude::mcp::__parse_options__
  export -f terminator::claude::mcp::__parse_scope_options__
  export -f terminator::claude::mcp::__parse_scope_flag__
  export -f terminator::claude::mcp::__remove__
  export -f terminator::claude::mcp::__project_root__
  export -f terminator::claude::mcp::__sync__
  export -f terminator::claude::mcp::enable::context7
  export -f terminator::claude::mcp::disable::context7
  export -f terminator::claude::mcp::enable::serena
  export -f terminator::claude::mcp::disable::serena
  export -f terminator::claude::mcp::enable::atlassian
  export -f terminator::claude::mcp::disable::atlassian
  export -f terminator::claude::settings::merge_baseline
  export -f terminator::claude::plugin::marketplace::exists
  export -f terminator::claude::plugin::marketplace::add
  export -f terminator::claude::plugin::__field__
  export -f terminator::claude::plugin::exists
  export -f terminator::claude::plugin::is_enabled
  export -f terminator::claude::plugin::__settle_disabled__
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
  export -fn terminator::claude::mcp::__parse_scope_options__
  export -fn terminator::claude::mcp::__parse_scope_flag__
  export -fn terminator::claude::mcp::__remove__
  export -fn terminator::claude::mcp::__project_root__
  export -fn terminator::claude::mcp::__sync__
  export -fn terminator::claude::mcp::enable::context7
  export -fn terminator::claude::mcp::disable::context7
  export -fn terminator::claude::mcp::enable::serena
  export -fn terminator::claude::mcp::disable::serena
  export -fn terminator::claude::mcp::enable::atlassian
  export -fn terminator::claude::mcp::disable::atlassian
  export -fn terminator::claude::settings::merge_baseline
  export -fn terminator::claude::plugin::marketplace::exists
  export -fn terminator::claude::plugin::marketplace::add
  export -fn terminator::claude::plugin::__field__
  export -fn terminator::claude::plugin::exists
  export -fn terminator::claude::plugin::is_enabled
  export -fn terminator::claude::plugin::__settle_disabled__
  export -fn terminator::claude::plugin::install
  export -fn terminator::claude::plugin::installed_version
  export -fn terminator::claude::plugin::installed_commit
  export -fn terminator::claude::plugin::__pin_and_reinstall__
  export -fn terminator::claude::plugin::sync
  export -fn terminator::claude::plugin::register
}
# KCOV_EXCL_STOP

terminator::__module__::export
