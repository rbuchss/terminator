#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/array.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

terminator::__module__::load || return 0

################################################################################
# Global state
################################################################################

TERMINATOR_VPN_NAMES=()
TERMINATOR_VPN_CONFS=()
TERMINATOR_VPN_CURRENT=""

# Directory scanned when resolving NAME -> NAME.conf (overridable via env).
TERMINATOR_VPN_CONF_DIR="${TERMINATOR_VPN_CONF_DIR:-${HOME}/.config/wireguard}"

# Directory where wg-quick records the logical-name -> real-interface mapping.
# Overridable so tests can point it at a temp dir.
TERMINATOR_VPN_RUN_DIR="${TERMINATOR_VPN_RUN_DIR:-/var/run/wireguard}"

################################################################################
# Enable / disable
################################################################################

function terminator::vpn::__enable__ {
  alias vpn-up='terminator::vpn::up'
  alias vpn-down='terminator::vpn::down'
  alias vpn-status='terminator::vpn::status'
  alias vpn-use='terminator::vpn::use'
  alias vpn-list='terminator::vpn::list'

  complete -F terminator::vpn::__completion__ vpn-up
  complete -F terminator::vpn::__completion__ vpn-down
  complete -F terminator::vpn::__completion__ vpn-status
  complete -F terminator::vpn::__completion__ vpn-use
}

function terminator::vpn::__disable__ {
  unalias vpn-up 2>/dev/null
  unalias vpn-down 2>/dev/null
  unalias vpn-status 2>/dev/null
  unalias vpn-use 2>/dev/null
  unalias vpn-list 2>/dev/null

  complete -r vpn-up 2>/dev/null
  complete -r vpn-down 2>/dev/null
  complete -r vpn-status 2>/dev/null
  complete -r vpn-use 2>/dev/null
}

################################################################################
# Internal functions
################################################################################

# Finds the index of NAME in TERMINATOR_VPN_NAMES.
# Returns 1 if not found.
function terminator::vpn::__index_of__ {
  local __index_of_result__

  for __index_of_result__ in "${!TERMINATOR_VPN_NAMES[@]}"; do
    if [[ "${TERMINATOR_VPN_NAMES[${__index_of_result__}]}" == "$1" ]]; then
      case "$#" in
        2) printf -v "$2" '%s' "${__index_of_result__}" ;;
        *) echo "${__index_of_result__}" ;;
      esac
      return 0
    fi
  done

  return 1
}

# Checks if a tunnel name is registered.
function terminator::vpn::__is_registered__ {
  terminator::array::contains "$1" "${TERMINATOR_VPN_NAMES[@]}"
}

# Looks up the conf path for a registered tunnel.
function terminator::vpn::__get_conf__ {
  local \
    idx \
    __get_conf_result__

  if ! terminator::vpn::__index_of__ "$1" idx; then
    return 1
  fi

  __get_conf_result__="${TERMINATOR_VPN_CONFS[${idx}]}"

  case "$#" in
    2) printf -v "$2" '%s' "${__get_conf_result__}" ;;
    *) echo "${__get_conf_result__}" ;;
  esac
}

# Extracts the explicit tunnel name from args (first positional), or empty if
# none was given. Does NOT apply the default -- callers decide the no-arg policy
# (up/down fall back to the default tunnel; status shows all). Sets the output
# var via printf -v. Returns 2 if -h/--help was requested.
# Usage: __resolve_name__ output_var "$@"
function terminator::vpn::__resolve_name__ {
  local \
    __resolve_name_out__="$1" \
    __resolve_name_result__="" \
    help=0
  shift

  while (($# != 0)); do
    case "$1" in
      -h | --help)
        help=1
        ;;
      *)
        # First positional wins; later positionals are ignored.
        [[ -z "${__resolve_name_result__}" ]] && __resolve_name_result__="$1"
        ;;
    esac
    shift
  done

  printf -v "${__resolve_name_out__}" '%s' "${__resolve_name_result__}"

  ((help == 1)) && return 2
  return 0
}

# Tests whether PATH is a live unix domain socket.
# Extracted so tests can override the filesystem check deterministically.
# The socket's own mode is root-only, but `-S` only stats it, which succeeds
# for any user because the parent dir is world-traversable.
function terminator::vpn::__is_live_socket__ {
  [[ -S "$1" ]]
}

# Reads the wg-quick name->interface mapping file, degrading to empty output
# when it is absent or unreadable. wg-quick writes it as root (mode 0400), so an
# unprivileged reader cannot read its contents; callers that already run
# privileged commands (status) pass READER='sudo cat' to read it, while
# unprivileged callers (list) omit it and simply get no mapping -- never a
# "Permission denied" leak.
# Usage: __read_name__ FILE [READER]
function terminator::vpn::__read_name__ {
  local \
    file="$1" \
    reader="$2"

  if [[ -n "${reader}" ]]; then
    # shellcheck disable=SC2086 # reader is an intentional command prefix
    ${reader} "${file}" 2>/dev/null
  elif [[ -r "${file}" ]]; then
    cat "${file}" 2>/dev/null
  fi
}

# Resolves the logical tunnel NAME to its real network interface.
#
# On macOS the kernel forces a utunN device; wg-quick records the mapping in
# ${TERMINATOR_VPN_RUN_DIR}/NAME.name. We trust that mapping only if the mapped
# interface still has a live socket -- mirroring wg-quick's own get_real_interface
# guard -- so a stale .name file left by an unclean teardown does not report a
# phantom interface. On Linux the .name file is absent and the interface equals
# NAME, so this cleanly falls back to NAME. The .name file is root-only, so pass
# READER='sudo cat' to actually read it; without it the mapping degrades to NAME.
# Usage: __real_interface__ NAME [output_var] [reader]
function terminator::vpn::__real_interface__ {
  local \
    name="$1" \
    run="${TERMINATOR_VPN_RUN_DIR:-/var/run/wireguard}" \
    mapped \
    __real_interface_result__

  mapped="$(terminator::vpn::__read_name__ "${run}/${name}.name" "$3")"
  if [[ -n "${mapped}" ]] \
    && ! terminator::vpn::__is_live_socket__ "${run}/${mapped}.sock"; then
    mapped=""
  fi

  __real_interface_result__="${mapped:-${name}}"

  if [[ -n "$2" ]]; then
    printf -v "$2" '%s' "${__real_interface_result__}"
  else
    echo "${__real_interface_result__}"
  fi
}

# Checks whether INTERFACE is an active WireGuard interface.
# Portable across OSes: `wg show interfaces` lists utunN on macOS and the conf
# name on Linux, so callers pass the resolved real interface.
function terminator::vpn::__interface_is_up__ {
  local \
    interface="$1" \
    active

  active="$(sudo wg show interfaces 2>/dev/null)"

  [[ " ${active} " == *" ${interface} "* ]]
}

# Ensures a conf file exists; errors otherwise. Used by up/down at use time so
# that a missing conf fails when acted on, not when registered.
function terminator::vpn::__require_conf__ {
  local conf="$1"

  if [[ ! -f "${conf}" ]]; then
    terminator::logger::error "VPN config not found: ${conf}"
    return 1
  fi
}

# Resolves a NAME-or-path token to the conf path to act on.
# Registration wins; an unregistered path-like token (contains '/' or ends in
# .conf) is treated as a literal conf path (the arbitrary-path escape hatch).
# Registered names can never contain '/' (register rejects them), so there is
# no name/path ambiguity. Returns 1 if the token is neither.
# Usage: __resolve_conf__ token output_var
function terminator::vpn::__resolve_conf__ {
  local \
    token="$1" \
    __resolve_conf_out__="$2" \
    __resolve_conf_result__

  if [[ -z "${token}" ]]; then
    return 1
  fi

  if terminator::vpn::__is_registered__ "${token}"; then
    terminator::vpn::__get_conf__ "${token}" __resolve_conf_result__
  elif [[ "${token}" == */* || "${token}" == *.conf ]]; then
    __resolve_conf_result__="${token}"
  else
    return 1
  fi

  printf -v "${__resolve_conf_out__}" '%s' "${__resolve_conf_result__}"
}

# Prints usage for a vpn command.
# Usage: __usage__ COMMAND DESCRIPTION [DEFAULT_HINT]
# DEFAULT_HINT describes the no-NAME behavior (defaults to the active tunnel).
# Pass '-' to omit the NAME argument entirely (for commands that take none).
function terminator::vpn::__usage__ {
  local \
    cmd="$1" \
    desc="$2" \
    default="${3:-${TERMINATOR_VPN_CURRENT:-none}}"

  if [[ "${default}" == '-' ]]; then
    cat <<USAGE_TEXT
Usage: ${cmd} [OPTIONS]

  ${desc}

  Options:
    -h, --help                Show this help

  Registered: ${TERMINATOR_VPN_NAMES[*]:-none}
USAGE_TEXT
    return 0
  fi

  cat <<USAGE_TEXT
Usage: ${cmd} [OPTIONS] [NAME]

  ${desc}

  Arguments:
    NAME                      Tunnel name (default: ${default})

  Options:
    -h, --help                Show this help

  Registered: ${TERMINATOR_VPN_NAMES[*]:-none}
USAGE_TEXT
}

# Shared implementation for up/down.
# Usage: __wg_quick__ up|down "$@"
function terminator::vpn::__wg_quick__ {
  local \
    action="$1" \
    desc \
    name \
    conf \
    rc
  shift

  case "${action}" in
    up) desc='Bring up a WireGuard tunnel (a registered name or a .conf path).' ;;
    *) desc='Tear down a WireGuard tunnel (a registered name or a .conf path).' ;;
  esac

  terminator::vpn::__resolve_name__ name "$@"
  rc=$?

  if ((rc == 2)); then
    terminator::vpn::__usage__ "vpn-${action}" "${desc}"
    return 0
  fi

  # No explicit name: fall back to the default (active) tunnel.
  [[ -z "${name}" ]] && name="${TERMINATOR_VPN_CURRENT}"

  if [[ -z "${name}" ]]; then
    terminator::logger::error 'no tunnel specified and no default set'
    terminator::vpn::__usage__ "vpn-${action}" "${desc}" >&2
    return 1
  fi

  if ! terminator::vpn::__resolve_conf__ "${name}" conf; then
    terminator::logger::error "'${name}' is not a registered tunnel"
    # shellcheck disable=SC2119 # list takes an optional -h/--help; none needed here
    terminator::vpn::list >&2
    return 1
  fi

  terminator::vpn::__require_conf__ "${conf}" || return 1

  sudo wg-quick "${action}" "${conf}"
}

################################################################################
# Public functions
################################################################################

# Registers a WireGuard tunnel by short name.
# Usage: register --name NAME [--conf PATH] [--conf-dir DIR] [--default]
#
# When --conf is omitted the conf path is resolved as ${conf_dir}/NAME.conf.
# Existence is NOT checked here: register runs at shell init, so a missing or
# not-yet-synced conf must not spam an error on every new shell. up/down enforce
# existence lazily via __require_conf__.
function terminator::vpn::register {
  local \
    name \
    conf \
    conf_dir="${TERMINATOR_VPN_CONF_DIR}" \
    default=0

  while (($# != 0)); do
    case "$1" in
      --name)
        shift
        name="$1"
        ;;
      --conf)
        shift
        conf="$1"
        ;;
      --conf-dir)
        shift
        conf_dir="$1"
        ;;
      --default)
        default=1
        ;;
      *)
        terminator::logger::error "register unknown option: '$1'"
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "${name}" ]]; then
    terminator::logger::error '--name is required'
    return 1
  fi

  # A name must never look like a path, so NAME and a literal conf path stay
  # unambiguous in up/down/__resolve_conf__.
  if [[ "${name}" == */* ]]; then
    terminator::logger::error "invalid tunnel name '${name}': must not contain '/'"
    return 1
  fi

  # Skip if already registered.
  if terminator::vpn::__is_registered__ "${name}"; then
    return 0
  fi

  # Resolve the conf path from the conf dir unless an explicit path was given.
  if [[ -z "${conf}" ]]; then
    conf="${conf_dir}/${name}.conf"
  fi

  TERMINATOR_VPN_NAMES+=("${name}")
  TERMINATOR_VPN_CONFS+=("${conf}")

  # First registration or explicit --default becomes the active tunnel.
  if [[ -z "${TERMINATOR_VPN_CURRENT}" ]] || ((default == 1)); then
    TERMINATOR_VPN_CURRENT="${name}"
  fi
}

# Switches or shows the active tunnel.
function terminator::vpn::use {
  local \
    name \
    rc

  terminator::vpn::__resolve_name__ name "$@"
  rc=$?

  if ((rc == 2)); then
    terminator::vpn::__usage__ vpn-use \
      'Show the active tunnel, or switch to NAME.' \
      'show active tunnel'
    return 0
  fi

  if [[ -z "${name}" ]]; then
    echo "Active: ${TERMINATOR_VPN_CURRENT:-none}"
    return 0
  fi

  if ! terminator::vpn::__is_registered__ "${name}"; then
    terminator::logger::error "'${name}' is not a registered tunnel"
    # shellcheck disable=SC2119 # list takes an optional -h/--help; none needed here
    terminator::vpn::list >&2
    return 1
  fi

  TERMINATOR_VPN_CURRENT="${name}"
}

# Lists all registered tunnels with an active marker and resolved interface.
# shellcheck disable=SC2120 # optional -h/--help; called without args internally
function terminator::vpn::list {
  local \
    entry \
    marker \
    conf \
    iface

  if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then
    terminator::vpn::__usage__ vpn-list 'List all registered tunnels.' '-'
    return 0
  fi

  echo 'Registered tunnels:'

  if ((${#TERMINATOR_VPN_NAMES[@]} == 0)); then
    echo '  (none)'
    return 0
  fi

  for entry in "${TERMINATOR_VPN_NAMES[@]}"; do
    if [[ "${entry}" == "${TERMINATOR_VPN_CURRENT}" ]]; then
      marker='* '
    else
      marker='  '
    fi

    terminator::vpn::__get_conf__ "${entry}" conf
    terminator::vpn::__real_interface__ "${entry}" iface

    if [[ "${iface}" == "${entry}" ]]; then
      echo "${marker}${entry} (conf: ${conf})"
    else
      echo "${marker}${entry} (conf: ${conf}, iface: ${iface})"
    fi
  done
}

# Brings up a WireGuard tunnel.
function terminator::vpn::up {
  terminator::vpn::__wg_quick__ up "$@"
}

# Tears down a WireGuard tunnel.
function terminator::vpn::down {
  terminator::vpn::__wg_quick__ down "$@"
}

# Shows WireGuard status. With no NAME, shows all interfaces (`wg show`).
# For a named tunnel, resolves the real interface and prints a legible
# `NAME -> INTERFACE` mapping so macOS utunN devices are understandable.
function terminator::vpn::status {
  local \
    name \
    rc \
    iface

  terminator::vpn::__resolve_name__ name "$@"
  rc=$?

  if ((rc == 2)); then
    terminator::vpn::__usage__ vpn-status \
      'Show WireGuard status for a tunnel, or all tunnels if no NAME is given.' \
      'all tunnels'
    return 0
  fi

  # No explicit name: show everything (do not fall back to the default tunnel).
  if [[ -z "${name}" ]]; then
    sudo wg show
    return
  fi

  if ! terminator::vpn::__is_registered__ "${name}"; then
    terminator::logger::error "'${name}' is not a registered tunnel"
    # shellcheck disable=SC2119 # list takes an optional -h/--help; none needed here
    terminator::vpn::list >&2
    return 1
  fi

  # Read the root-only .name mapping with the same privilege used for wg show.
  terminator::vpn::__real_interface__ "${name}" iface 'sudo cat'

  # Determine liveness before printing so a down tunnel does not emit a
  # misleading mapping followed by a `wg show` failure.
  if ! terminator::vpn::__interface_is_up__ "${iface}"; then
    echo "Tunnel '${name}' is not up"
    return 1
  fi

  echo "${name} -> ${iface}"
  sudo wg show "${iface}"
}

################################################################################
# Completion
################################################################################

# Tab completion for vpn-up/down/status/use: completes the tunnel name in the
# first positional slot; offers -h/--help on a dash.
function terminator::vpn::__completion__ {
  local \
    cur \
    completion

  if ((COMP_CWORD > 1)); then
    return
  fi

  cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "${cur}" == -* ]]; then
    COMPREPLY=()
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W '-h --help' -- "${cur}")
    return
  fi

  COMPREPLY=()
  while IFS='' read -r completion; do
    COMPREPLY+=("${completion}")
  done < <(compgen -W "${TERMINATOR_VPN_NAMES[*]}" -- "${cur}")
}

################################################################################
# Export / recall
################################################################################

function terminator::vpn::__export__ {
  export TERMINATOR_VPN_NAMES
  export TERMINATOR_VPN_CONFS
  export TERMINATOR_VPN_CURRENT
  export TERMINATOR_VPN_CONF_DIR
  export TERMINATOR_VPN_RUN_DIR

  export -f terminator::vpn::__index_of__
  export -f terminator::vpn::__is_registered__
  export -f terminator::vpn::__get_conf__
  export -f terminator::vpn::__resolve_name__
  export -f terminator::vpn::__is_live_socket__
  export -f terminator::vpn::__read_name__
  export -f terminator::vpn::__real_interface__
  export -f terminator::vpn::__interface_is_up__
  export -f terminator::vpn::__require_conf__
  export -f terminator::vpn::__resolve_conf__
  export -f terminator::vpn::__usage__
  export -f terminator::vpn::__wg_quick__
  export -f terminator::vpn::register
  export -f terminator::vpn::use
  export -f terminator::vpn::list
  export -f terminator::vpn::up
  export -f terminator::vpn::down
  export -f terminator::vpn::status
  export -f terminator::vpn::__completion__
}

# KCOV_EXCL_START
function terminator::vpn::__recall__ {
  unset TERMINATOR_VPN_NAMES
  unset TERMINATOR_VPN_CONFS
  unset TERMINATOR_VPN_CURRENT
  unset TERMINATOR_VPN_CONF_DIR
  unset TERMINATOR_VPN_RUN_DIR

  export -fn terminator::vpn::__index_of__
  export -fn terminator::vpn::__is_registered__
  export -fn terminator::vpn::__get_conf__
  export -fn terminator::vpn::__resolve_name__
  export -fn terminator::vpn::__is_live_socket__
  export -fn terminator::vpn::__read_name__
  export -fn terminator::vpn::__real_interface__
  export -fn terminator::vpn::__interface_is_up__
  export -fn terminator::vpn::__require_conf__
  export -fn terminator::vpn::__resolve_conf__
  export -fn terminator::vpn::__usage__
  export -fn terminator::vpn::__wg_quick__
  export -fn terminator::vpn::register
  export -fn terminator::vpn::use
  export -fn terminator::vpn::list
  export -fn terminator::vpn::up
  export -fn terminator::vpn::down
  export -fn terminator::vpn::status
  export -fn terminator::vpn::__completion__
}
# KCOV_EXCL_STOP

terminator::__module__::export
