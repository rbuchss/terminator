#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

terminator::__module__::load || return 0

################################################################################
# Global state
################################################################################

TERMINATOR_WORKSTATION_NAMES=()
TERMINATOR_WORKSTATION_PROVIDERS=()
TERMINATOR_WORKSTATION_AUTH_HOOKS=()
TERMINATOR_WORKSTATION_CURRENT=""

################################################################################
# Internal functions
################################################################################

# Finds the index of NAME in TERMINATOR_WORKSTATION_NAMES.
# Returns 1 if not found.
function terminator::workstation::__index_of__ {
  local __index_of_name__="$1"
  local __index_of_i__

  for __index_of_i__ in "${!TERMINATOR_WORKSTATION_NAMES[@]}"; do
    if [[ "${TERMINATOR_WORKSTATION_NAMES[${__index_of_i__}]}" == "${__index_of_name__}" ]]; then
      case "$#" in
        2) printf -v "$2" '%s' "${__index_of_i__}" ;;
        *) echo "${__index_of_i__}" ;;
      esac
      return 0
    fi
  done

  return 1
}

# Checks if a workstation name is registered.
function terminator::workstation::__is_registered__ {
  local __entry__

  for __entry__ in "${TERMINATOR_WORKSTATION_NAMES[@]}"; do
    [[ "${__entry__}" == "$1" ]] && return 0
  done

  return 1
}

# Looks up the provider for a registered workstation.
function terminator::workstation::__get_provider__ {
  local __get_prov_name__="$1"
  local __get_prov_idx__

  if ! terminator::workstation::__index_of__ "${__get_prov_name__}" __get_prov_idx__; then
    return 1
  fi

  local __get_prov_result__="${TERMINATOR_WORKSTATION_PROVIDERS[${__get_prov_idx__}]}"

  case "$#" in
    2) printf -v "$2" '%s' "${__get_prov_result__}" ;;
    *) echo "${__get_prov_result__}" ;;
  esac
}

# Looks up the auth hook for a registered workstation.
function terminator::workstation::__get_auth_hook__ {
  local __get_hook_name__="$1"
  local __get_hook_idx__

  if ! terminator::workstation::__index_of__ "${__get_hook_name__}" __get_hook_idx__; then
    return 1
  fi

  local __get_hook_result__="${TERMINATOR_WORKSTATION_AUTH_HOOKS[${__get_hook_idx__}]}"

  case "$#" in
    2) printf -v "$2" '%s' "${__get_hook_result__}" ;;
    *) echo "${__get_hook_result__}" ;;
  esac
}

# Scans args for INSTANCE:PATH pattern matching a registered workstation.
# Usage: __extract_instance__ output_var "$@"
function terminator::workstation::__extract_instance__ {
  local __extract_out__="$1"
  shift

  local __extract_arg__ __extract_candidate__

  for __extract_arg__ in "$@"; do
    if [[ "${__extract_arg__}" == *:* ]]; then
      __extract_candidate__="${__extract_arg__%%:*}"

      if terminator::workstation::__is_registered__ "${__extract_candidate__}"; then
        printf -v "${__extract_out__}" '%s' "${__extract_candidate__}"
        return 0
      fi
    fi
  done

  return 1
}

# Parses -w/--workstation and -h/--help from args.
# Sets instance via printf -v and passthrough args via __TERMINATOR_WS_PASSTHROUGH__.
# Returns 2 if help was requested.
# Usage: __parse_instance__ instance_var "$@"
function terminator::workstation::__parse_instance__ {
  local __pi_inst_out__="$1"
  shift

  local __pi_inst__="" __pi_help__=0
  __TERMINATOR_WS_PASSTHROUGH__=()

  while (($# != 0)); do
    case "$1" in
      -w | --workstation)
        shift
        __pi_inst__="$1"
        ;;
      -h | --help)
        __pi_help__=1
        ;;
      *)
        __TERMINATOR_WS_PASSTHROUGH__+=("$1")
        ;;
    esac
    shift
  done

  printf -v "${__pi_inst_out__}" '%s' "${__pi_inst__:-${TERMINATOR_WORKSTATION_CURRENT}}"

  ((__pi_help__ == 1)) && return 2
  return 0
}

# Calls the stored auth hook function if set.
function terminator::workstation::__run_auth_hook__ {
  local __auth_name__="$1"
  local __auth_hook__

  terminator::workstation::__get_auth_hook__ "${__auth_name__}" __auth_hook__

  if [[ -z "${__auth_hook__}" ]]; then
    return 0
  fi

  if ! terminator::command::exists "${__auth_hook__}"; then
    echo "ERROR: auth hook '${__auth_hook__}' not found" >&2
    return 1
  fi

  "${__auth_hook__}"
}

# Generic rsync transport dispatcher.
# Called in a child bash by rsync -e. Reads provider from env, shifts
# hostname (injected by rsync), then delegates to the provider's rsync_rsh.
function terminator::workstation::__rsync_rsh__ {
  shift
  "terminator::workstation::provider::${__TERMINATOR_RSYNC_PROVIDER__}::rsync_rsh" "$@"
}

################################################################################
# Public functions
################################################################################

# Registers a workstation.
# Usage: register --name NAME --provider PROVIDER [--auth-hook FUNC] [EXTRA_ARGS...]
function terminator::workstation::register {
  local __reg_name__="" __reg_provider__="" __reg_auth_hook__="" __reg_default__=0 __reg_extra__=()

  while (($# != 0)); do
    case "$1" in
      --name)
        shift
        __reg_name__="$1"
        ;;
      --provider)
        shift
        __reg_provider__="$1"
        ;;
      --auth-hook)
        shift
        __reg_auth_hook__="$1"
        ;;
      --default)
        __reg_default__=1
        ;;
      *)
        __reg_extra__+=("$1")
        ;;
    esac
    shift
  done

  if [[ -z "${__reg_name__}" ]]; then
    echo "ERROR: --name is required" >&2
    return 1
  fi

  if [[ -z "${__reg_provider__}" ]]; then
    echo "ERROR: --provider is required" >&2
    return 1
  fi

  # Skip if already registered
  if terminator::workstation::__is_registered__ "${__reg_name__}"; then
    return 0
  fi

  # If no auth hook given, check if the provider defines a default
  if [[ -z "${__reg_auth_hook__}" ]]; then
    local __reg_default_auth__="terminator::workstation::provider::${__reg_provider__}::auth"
    if terminator::command::exists "${__reg_default_auth__}"; then
      __reg_auth_hook__="${__reg_default_auth__}"
    fi
  fi

  TERMINATOR_WORKSTATION_NAMES+=("${__reg_name__}")
  TERMINATOR_WORKSTATION_PROVIDERS+=("${__reg_provider__}")
  TERMINATOR_WORKSTATION_AUTH_HOOKS+=("${__reg_auth_hook__}")

  # First registration or explicit --default becomes the active workstation
  if [[ -z "${TERMINATOR_WORKSTATION_CURRENT}" ]] || ((__reg_default__ == 1)); then
    TERMINATOR_WORKSTATION_CURRENT="${__reg_name__}"
  fi

  # Auto-call provider configure if the function exists
  local __reg_configure_func__="terminator::workstation::provider::${__reg_provider__}::configure"
  if terminator::command::exists "${__reg_configure_func__}"; then
    "${__reg_configure_func__}" --name "${__reg_name__}" "${__reg_extra__[@]}"
  fi
}

# Switches or shows the active workstation.
function terminator::workstation::use {
  if (($# == 0)); then
    echo "Active: ${TERMINATOR_WORKSTATION_CURRENT:-none}"
    return 0
  fi

  if ! terminator::workstation::__is_registered__ "$1"; then
    echo "ERROR: '$1' is not a registered workstation" >&2
    terminator::workstation::list >&2
    return 1
  fi

  TERMINATOR_WORKSTATION_CURRENT="$1"
}

# Lists all registered workstations with active marker.
function terminator::workstation::list {
  local __list_entry__ __list_marker__ __list_provider__ __list_info__

  echo "Registered workstations:"

  for __list_entry__ in "${TERMINATOR_WORKSTATION_NAMES[@]}"; do
    if [[ "${__list_entry__}" == "${TERMINATOR_WORKSTATION_CURRENT}" ]]; then
      __list_marker__="* "
    else
      __list_marker__="  "
    fi

    terminator::workstation::__get_provider__ "${__list_entry__}" __list_provider__

    local __list_format_func__="terminator::workstation::provider::${__list_provider__}::format_info"
    if terminator::command::exists "${__list_format_func__}"; then
      __list_info__="$("${__list_format_func__}" "${__list_entry__}")"
      echo "${__list_marker__}${__list_entry__} (${__list_info__})"
    else
      echo "${__list_marker__}${__list_entry__} (provider: ${__list_provider__})"
    fi
  done
}

################################################################################
# SSH
################################################################################

function terminator::workstation::ssh::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [COMMAND...]

  SSH into a workstation via the configured provider.

  Options:
    -w, --workstation NAME    Target workstation (default: ${TERMINATOR_WORKSTATION_CURRENT:-none})
    -h, --help                Show this help

  Examples:
    ${FUNCNAME[1]}                                  # interactive, default workstation
    ${FUNCNAME[1]} ls -la                           # run command on default
    ${FUNCNAME[1]} -w dev-workstation               # interactive, specific workstation
    ${FUNCNAME[1]} -w dev-workstation ls -la        # run command on specific

  Registered: ${TERMINATOR_WORKSTATION_NAMES[*]:-none}
USAGE_TEXT
}

function terminator::workstation::ssh {
  local __ssh_instance__

  terminator::workstation::__parse_instance__ __ssh_instance__ "$@"
  local __ssh_parse_rc__=$?

  if ((__ssh_parse_rc__ == 2)); then
    terminator::workstation::ssh::usage
    return 0
  fi

  if [[ -z "${__ssh_instance__}" ]]; then
    echo "ERROR: no workstation specified and no default set" >&2
    terminator::workstation::ssh::usage >&2
    return 1
  fi

  if ! terminator::workstation::__is_registered__ "${__ssh_instance__}"; then
    echo "ERROR: '${__ssh_instance__}' is not a registered workstation" >&2
    terminator::workstation::list >&2
    return 1
  fi

  terminator::workstation::__run_auth_hook__ "${__ssh_instance__}" || return 1

  local __ssh_provider__
  terminator::workstation::__get_provider__ "${__ssh_instance__}" __ssh_provider__

  "terminator::workstation::provider::${__ssh_provider__}::ssh" \
    "${__ssh_instance__}" "${__TERMINATOR_WS_PASSTHROUGH__[@]}"
}

################################################################################
# SCP
################################################################################

function terminator::workstation::scp::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] SRC DEST

  Copy files to/from a workstation via the configured provider.
  Prefix remote paths with WORKSTATION_NAME:

  Options:
    -w, --workstation NAME    Override workstation (default: auto-detect from path)
    -h, --help                Show this help

  Examples:
    ${FUNCNAME[1]} russ-workstation:~/remote-file ./local-path
    ${FUNCNAME[1]} ./local-file russ-workstation:~/remote-path
    ${FUNCNAME[1]} --recurse ./local-dir russ-workstation:~/remote-dir

  Extra options are passed through to the provider.
  Registered: ${TERMINATOR_WORKSTATION_NAMES[*]:-none}
USAGE_TEXT
}

function terminator::workstation::scp {
  local __scp_instance__

  terminator::workstation::__parse_instance__ __scp_instance__ "$@"
  local __scp_parse_rc__=$?

  if ((__scp_parse_rc__ == 2)) || (($# == 0)); then
    terminator::workstation::scp::usage
    ((__scp_parse_rc__ == 2)) && return 0
    return 1
  fi

  # If -w wasn't given, try to extract from the paths
  if [[ "${__scp_instance__}" == "${TERMINATOR_WORKSTATION_CURRENT}" ]]; then
    terminator::workstation::__extract_instance__ __scp_instance__ "${__TERMINATOR_WS_PASSTHROUGH__[@]}" \
      || __scp_instance__="${TERMINATOR_WORKSTATION_CURRENT}"
  fi

  if [[ -z "${__scp_instance__}" ]]; then
    echo "ERROR: no workstation found in args and no default set" >&2
    terminator::workstation::scp::usage >&2
    return 1
  fi

  if ! terminator::workstation::__is_registered__ "${__scp_instance__}"; then
    echo "ERROR: '${__scp_instance__}' is not a registered workstation" >&2
    terminator::workstation::list >&2
    return 1
  fi

  terminator::workstation::__run_auth_hook__ "${__scp_instance__}" || return 1

  local __scp_provider__
  terminator::workstation::__get_provider__ "${__scp_instance__}" __scp_provider__

  "terminator::workstation::provider::${__scp_provider__}::scp" \
    "${__scp_instance__}" "${__TERMINATOR_WS_PASSTHROUGH__[@]}"
}

################################################################################
# Rsync
################################################################################

function terminator::workstation::rsync::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] SRC DEST

  Rsync files to/from a workstation via the configured provider.
  Prefix remote paths with WORKSTATION_NAME:
  Excludes: ${TERMINATOR_RSYNC_EXCLUDE_DIRS[*]:-none}

  Options:
    -w, --workstation NAME    Override workstation (default: auto-detect from path)
    -h, --help                Show this help

  Examples:
    ${FUNCNAME[1]} ./local-dir/ russ-workstation:~/remote-dir/
    ${FUNCNAME[1]} russ-workstation:~/remote-dir/ ./local-dir/

  Extra options are passed through to rsync.
  Registered: ${TERMINATOR_WORKSTATION_NAMES[*]:-none}
USAGE_TEXT
}

function terminator::workstation::rsync {
  local __rsync_instance__

  terminator::workstation::__parse_instance__ __rsync_instance__ "$@"
  local __rsync_parse_rc__=$?

  if ((__rsync_parse_rc__ == 2)) || (($# == 0)); then
    terminator::workstation::rsync::usage
    ((__rsync_parse_rc__ == 2)) && return 0
    return 1
  fi

  # If -w wasn't given, try to extract from the paths
  if [[ "${__rsync_instance__}" == "${TERMINATOR_WORKSTATION_CURRENT}" ]]; then
    terminator::workstation::__extract_instance__ __rsync_instance__ "${__TERMINATOR_WS_PASSTHROUGH__[@]}" \
      || __rsync_instance__="${TERMINATOR_WORKSTATION_CURRENT}"
  fi

  if [[ -z "${__rsync_instance__}" ]]; then
    echo "ERROR: no workstation found in args and no default set" >&2
    terminator::workstation::rsync::usage >&2
    return 1
  fi

  if ! terminator::workstation::__is_registered__ "${__rsync_instance__}"; then
    echo "ERROR: '${__rsync_instance__}' is not a registered workstation" >&2
    terminator::workstation::list >&2
    return 1
  fi

  terminator::workstation::__run_auth_hook__ "${__rsync_instance__}" || return 1

  local __rsync_provider__
  terminator::workstation::__get_provider__ "${__rsync_instance__}" __rsync_provider__

  # Let the provider export its env vars for the child process
  "terminator::workstation::provider::${__rsync_provider__}::rsync_export_env" "${__rsync_instance__}"

  export __TERMINATOR_RSYNC_PROVIDER__="${__rsync_provider__}"

  local \
    __rsync_excludes__=() \
    __rsync_exclude_dir__

  for __rsync_exclude_dir__ in "${TERMINATOR_RSYNC_EXCLUDE_DIRS[@]}"; do
    __rsync_excludes__+=("--exclude=${__rsync_exclude_dir__}")
  done

  if ! terminator::command::exists rsync; then
    terminator::logger::error "rsync is not installed locally"
    return 1
  fi

  echo "running: rsync -avz --progress ${__rsync_excludes__[*]} -e '...' ${__TERMINATOR_WS_PASSTHROUGH__[*]}"

  rsync -avz --progress \
    "${__rsync_excludes__[@]}" \
    -e 'bash -c '\''terminator::workstation::__rsync_rsh__ "$@"'\'' _' \
    "${__TERMINATOR_WS_PASSTHROUGH__[@]}"

  local __rsync_rc__=$?
  if ((__rsync_rc__ == 12)); then
    terminator::logger::warning "rsync may not be installed on the remote workstation"
    terminator::logger::warning "  install it with: workstation-ssh -w ${__rsync_instance__} 'sudo apt install rsync'"
  fi
  return "${__rsync_rc__}"
}

################################################################################
# GCP provider
################################################################################

TERMINATOR_WORKSTATION_GCP_ZONES=()
TERMINATOR_WORKSTATION_GCP_PROJECTS=()

# Configures GCP-specific settings for a workstation.
# Called automatically by core register with passthrough args.
# Default auth hook for the GCP provider. Delegates to terminator::gcloud::auth.
function terminator::workstation::provider::gcp::auth {
  terminator::gcloud::auth "$@"
}

# Configures GCP-specific settings for a workstation.
# Called automatically by core register with passthrough args.
function terminator::workstation::provider::gcp::configure {
  local __gcp_conf_name__="" __gcp_conf_zone__="" __gcp_conf_project__=""

  while (($# != 0)); do
    case "$1" in
      --name)
        shift
        __gcp_conf_name__="$1"
        ;;
      --zone)
        shift
        __gcp_conf_zone__="$1"
        ;;
      --project)
        shift
        __gcp_conf_project__="$1"
        ;;
      *)
        echo "ERROR: provider::gcp::configure unknown option: '$1'" >&2
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "${__gcp_conf_name__}" ]]; then
    echo "ERROR: provider::gcp::configure --name is required" >&2
    return 1
  fi

  local __gcp_conf_idx__
  if ! terminator::workstation::__index_of__ "${__gcp_conf_name__}" __gcp_conf_idx__; then
    echo "ERROR: '${__gcp_conf_name__}' is not registered" >&2
    return 1
  fi

  TERMINATOR_WORKSTATION_GCP_ZONES[__gcp_conf_idx__]="${__gcp_conf_zone__}"
  TERMINATOR_WORKSTATION_GCP_PROJECTS[__gcp_conf_idx__]="${__gcp_conf_project__}"
}

# SSH into a GCP instance via gcloud compute ssh.
function terminator::workstation::provider::gcp::ssh {
  local __gcp_ssh_instance__="$1"
  shift

  local __gcp_ssh_idx__
  terminator::workstation::__index_of__ "${__gcp_ssh_instance__}" __gcp_ssh_idx__

  local __gcp_ssh_zone__="${TERMINATOR_WORKSTATION_GCP_ZONES[${__gcp_ssh_idx__}]}"
  local __gcp_ssh_project__="${TERMINATOR_WORKSTATION_GCP_PROJECTS[${__gcp_ssh_idx__}]}"

  gcloud compute ssh \
    --zone "${__gcp_ssh_zone__}" \
    "${__gcp_ssh_instance__}" \
    --project "${__gcp_ssh_project__}" \
    -- "$@"
}

# SCP files to/from a GCP instance via gcloud compute scp.
function terminator::workstation::provider::gcp::scp {
  local __gcp_scp_instance__="$1"
  shift

  local __gcp_scp_idx__
  terminator::workstation::__index_of__ "${__gcp_scp_instance__}" __gcp_scp_idx__

  local __gcp_scp_zone__="${TERMINATOR_WORKSTATION_GCP_ZONES[${__gcp_scp_idx__}]}"
  local __gcp_scp_project__="${TERMINATOR_WORKSTATION_GCP_PROJECTS[${__gcp_scp_idx__}]}"

  gcloud compute scp \
    --zone "${__gcp_scp_zone__}" \
    --project "${__gcp_scp_project__}" \
    "$@"
}

# Exports env vars for rsync child process.
function terminator::workstation::provider::gcp::rsync_export_env {
  local __gcp_rsync_instance__="$1"
  local __gcp_rsync_idx__

  terminator::workstation::__index_of__ "${__gcp_rsync_instance__}" __gcp_rsync_idx__

  export __TERMINATOR_RSYNC_GCP_ZONE__="${TERMINATOR_WORKSTATION_GCP_ZONES[${__gcp_rsync_idx__}]}"
  export __TERMINATOR_RSYNC_GCP_INSTANCE__="${__gcp_rsync_instance__}"
  export __TERMINATOR_RSYNC_GCP_PROJECT__="${TERMINATOR_WORKSTATION_GCP_PROJECTS[${__gcp_rsync_idx__}]}"
}

# Rsync transport for GCP. Called in child bash via exec.
function terminator::workstation::provider::gcp::rsync_rsh {
  exec gcloud compute ssh \
    --zone "${__TERMINATOR_RSYNC_GCP_ZONE__}" \
    "${__TERMINATOR_RSYNC_GCP_INSTANCE__}" \
    --project "${__TERMINATOR_RSYNC_GCP_PROJECT__}" \
    -- "$@"
}

# Formats info for workstation list output.
function terminator::workstation::provider::gcp::format_info {
  local __gcp_info_instance__="$1"
  local __gcp_info_idx__

  terminator::workstation::__index_of__ "${__gcp_info_instance__}" __gcp_info_idx__

  echo "zone: ${TERMINATOR_WORKSTATION_GCP_ZONES[${__gcp_info_idx__}]}, project: ${TERMINATOR_WORKSTATION_GCP_PROJECTS[${__gcp_info_idx__}]}"
}

################################################################################
# Completion
################################################################################

# Tab completion for -w/--workstation flag across ssh/scp/rsync commands.
function terminator::workstation::__completion__ {
  local cur prev

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  if [[ "${prev}" == "-w" || "${prev}" == "--workstation" ]]; then
    COMPREPLY=()
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "${TERMINATOR_WORKSTATION_NAMES[*]}" -- "${cur}")
    return
  fi

  # Offer flags when typing a dash
  if [[ "${cur}" == -* ]]; then
    COMPREPLY=()
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "-w --workstation -h --help" -- "${cur}")
    return
  fi
}

# Completion for workstation-use (single workstation name, no flags).
function terminator::workstation::__use_completion__ {
  if ((COMP_CWORD > 1)); then
    return
  fi

  local cur="${COMP_WORDS[COMP_CWORD]}"

  COMPREPLY=()
  while IFS='' read -r completion; do
    COMPREPLY+=("${completion}")
  done < <(compgen -W "${TERMINATOR_WORKSTATION_NAMES[*]}" -- "${cur}")
}

################################################################################
# Lifecycle
################################################################################

function terminator::workstation::__enable__ {
  alias workstation-ssh='terminator::workstation::ssh'
  alias workstation-scp='terminator::workstation::scp'
  alias workstation-rsync='terminator::workstation::rsync'
  alias workstation-use='terminator::workstation::use'
  alias workstation-list='terminator::workstation::list'

  complete -F terminator::workstation::__completion__ workstation-ssh
  complete -F terminator::workstation::__completion__ workstation-scp
  complete -F terminator::workstation::__completion__ workstation-rsync
  complete -F terminator::workstation::__use_completion__ workstation-use
}

function terminator::workstation::__disable__ {
  unalias workstation-ssh 2>/dev/null
  unalias workstation-scp 2>/dev/null
  unalias workstation-rsync 2>/dev/null
  unalias workstation-use 2>/dev/null
  unalias workstation-list 2>/dev/null

  complete -r workstation-ssh 2>/dev/null
  complete -r workstation-scp 2>/dev/null
  complete -r workstation-rsync 2>/dev/null
  complete -r workstation-use 2>/dev/null
}

function terminator::workstation::__export__ {
  export TERMINATOR_WORKSTATION_NAMES
  export TERMINATOR_WORKSTATION_PROVIDERS
  export TERMINATOR_WORKSTATION_AUTH_HOOKS
  export TERMINATOR_WORKSTATION_CURRENT
  export TERMINATOR_WORKSTATION_GCP_ZONES
  export TERMINATOR_WORKSTATION_GCP_PROJECTS

  export -f terminator::workstation::__index_of__
  export -f terminator::workstation::__is_registered__
  export -f terminator::workstation::__get_provider__
  export -f terminator::workstation::__get_auth_hook__
  export -f terminator::workstation::__extract_instance__
  export -f terminator::workstation::__parse_instance__
  export -f terminator::workstation::__run_auth_hook__
  export -f terminator::workstation::__rsync_rsh__
  export -f terminator::workstation::register
  export -f terminator::workstation::use
  export -f terminator::workstation::list
  export -f terminator::workstation::ssh
  export -f terminator::workstation::ssh::usage
  export -f terminator::workstation::scp
  export -f terminator::workstation::scp::usage
  export -f terminator::workstation::rsync
  export -f terminator::workstation::rsync::usage
  export -f terminator::workstation::provider::gcp::auth
  export -f terminator::workstation::provider::gcp::configure
  export -f terminator::workstation::provider::gcp::ssh
  export -f terminator::workstation::provider::gcp::scp
  export -f terminator::workstation::provider::gcp::rsync_export_env
  export -f terminator::workstation::provider::gcp::rsync_rsh
  export -f terminator::workstation::provider::gcp::format_info
  export -f terminator::workstation::__completion__
  export -f terminator::workstation::__use_completion__
}

# KCOV_EXCL_START
function terminator::workstation::__recall__ {
  unset TERMINATOR_WORKSTATION_NAMES
  unset TERMINATOR_WORKSTATION_PROVIDERS
  unset TERMINATOR_WORKSTATION_AUTH_HOOKS
  unset TERMINATOR_WORKSTATION_CURRENT
  unset TERMINATOR_WORKSTATION_GCP_ZONES
  unset TERMINATOR_WORKSTATION_GCP_PROJECTS

  export -fn terminator::workstation::__index_of__
  export -fn terminator::workstation::__is_registered__
  export -fn terminator::workstation::__get_provider__
  export -fn terminator::workstation::__get_auth_hook__
  export -fn terminator::workstation::__extract_instance__
  export -fn terminator::workstation::__parse_instance__
  export -fn terminator::workstation::__run_auth_hook__
  export -fn terminator::workstation::__rsync_rsh__
  export -fn terminator::workstation::register
  export -fn terminator::workstation::use
  export -fn terminator::workstation::list
  export -fn terminator::workstation::ssh
  export -fn terminator::workstation::ssh::usage
  export -fn terminator::workstation::scp
  export -fn terminator::workstation::scp::usage
  export -fn terminator::workstation::rsync
  export -fn terminator::workstation::rsync::usage
  export -fn terminator::workstation::provider::gcp::auth
  export -fn terminator::workstation::provider::gcp::configure
  export -fn terminator::workstation::provider::gcp::ssh
  export -fn terminator::workstation::provider::gcp::scp
  export -fn terminator::workstation::provider::gcp::rsync_export_env
  export -fn terminator::workstation::provider::gcp::rsync_rsh
  export -fn terminator::workstation::provider::gcp::format_info
  export -fn terminator::workstation::__completion__
  export -fn terminator::workstation::__use_completion__
}
# KCOV_EXCL_STOP

terminator::__module__::export
