#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"

terminator::__module__::load || return 0

TERMINATOR_SSH_DEFAULT_KEY_TYPE='ed25519'
TERMINATOR_SSH_INVALID_STATUS=255

function terminator::ssh::__enable__ {
  alias ssh-init='terminator::ssh::find_and_add_keys'
  alias ssh-generate='terminator::ssh::generate_key'
}

function terminator::ssh::__disable__ {
  unalias ssh-init
  unalias ssh-generate
}

function terminator::ssh::is_ssh_session {
  if [[ -n "${TERMINATOR_SSH_IS_SSH_SESSION}" ]]; then
    (( TERMINATOR_SSH_IS_SSH_SESSION == 0 )) && return 1
    (( TERMINATOR_SSH_IS_SSH_SESSION == 1 )) && return 0
  fi

  [[ -n "${SSH_CLIENT}" ]] \
    || [[ -n "${SSH_TTY}" ]] \
    || terminator::ssh::is_ssh_sudo "$@"

  result=$?

  if (( result == 0 )); then
    TERMINATOR_SSH_IS_SSH_SESSION=1
  else
    TERMINATOR_SSH_IS_SSH_SESSION=0
  fi

  export TERMINATOR_SSH_IS_SSH_SESSION
  return "${result}"
}

function terminator::ssh::ppinfo {
  command ps -p "${1:-$$}" -o ppid= -o comm=
}

function terminator::ssh::is_ssh_sudo {
  local \
    regexp='^([[:digit:]]+)[[:space:]]+(sshd: (.*))?' \
    ppinfo \
    ppid \
    ssh_user

  ppinfo="$(terminator::ssh::ppinfo "${1:-$$}")"

  if [[ "${ppinfo}" =~ $regexp ]]; then
    ppid="${BASH_REMATCH[1]}"
    ssh_user="${BASH_REMATCH[3]}"

    terminator::logger::debug "ppid: '${ppid}' ssh_user: '${ssh_user}'"

    if [[ -n "${ssh_user}" ]]; then
      return 0
    elif [[ -z "${ppid}" ]] || (( ppid == 0 )); then
      return 1
    fi

    terminator::ssh::is_ssh_sudo "${ppid}"
    return
  fi

  return 1
}

function terminator::ssh::find_keys {
  find -L \
    "${HOME}/.ssh" \
    -maxdepth 1 \
    -name '*.pub' \
    \( -type f -o -type l \) \
    | sed 's/\.[^.]*$//'
}

function terminator::ssh::find_and_add_keys {
  local \
    ssh_key_path \
    ssh_key_paths=()

  if ! terminator::command::exists fzf; then
    terminator::logger::error 'Requires fzf which was not found - Exiting'
    return 1
  fi

  while IFS= read -r ssh_key_path; do
    ssh_key_paths+=("${ssh_key_path}")
  done < <(terminator::ssh::find_keys | fzf --multi --header='Select ssh keys to add')

  if (( ${#ssh_key_paths[@]} == 0 )); then
    terminator::logger::warning 'No ssh keys found - Exiting'
    return 1
  fi

  terminator::logger::info "Selected ssh keys: [${ssh_key_paths[*]}]"

  for ssh_key_path in "${ssh_key_paths[@]}"; do
    terminator::ssh::add_key "${ssh_key_path}"
  done
}

function terminator::ssh::add_key {
  local ssh_key_path="${1:?}"

  if [[ ! -f "${ssh_key_path}" ]]; then
    terminator::logger::warning "Cannot find ssh private key: '${ssh_key_path}' - Exiting"
    return 1
  fi

  if [[ ! -f "${ssh_key_path}.pub" ]]; then
    terminator::logger::warning "Cannot find ssh public key: '${ssh_key_path}.pub' - Exiting"
    return 1
  fi

  # Check if public key already exists in ssh authentication agent - if so just noop
  if command ssh-add -L | command grep -q -f "${ssh_key_path}.pub"; then
    terminator::logger::info "ssh-identity '${ssh_key_path}' found in authentication agent - Noop"
    return
  fi

  terminator::logger::info "ssh-identity '${ssh_key_path}' NOT found in authentication agent - Adding"

  terminator::os::switch \
    --darwin terminator::ssh::add_key::os::darwin \
    --linux terminator::ssh::add_key::os::linux \
    --windows terminator::ssh::add_key::os::windows \
    --unsupported terminator::ssh::add_key::os::unsupported \
    "${ssh_key_path}"
}

function terminator::ssh::add_key::os::darwin {
  local ssh_add_path_for_darwin='/usr/bin/ssh-add'

  if ! [[ -x "${ssh_add_path_for_darwin}" ]]; then
    local ssh_add_fallback_path

    ssh_add_fallback_path="$(command -v ssh-add)"

    terminator::logger::warning "Cannot find ssh-add darwin default at: '${ssh_add_path_for_darwin}' - Falling back to first in PATH: '${ssh_add_fallback_path}'"

    command ssh-add "${1:?}"
  fi

  "${ssh_add_path_for_darwin}" --apple-use-keychain "${1:?}"
}

function terminator::ssh::add_key::os::linux {
  command ssh-add "${1:?}"
}

function terminator::ssh::add_key::os::windows {
  command ssh-add "${1:?}"
}

function terminator::ssh::add_key::os::unsupported {
  terminator::logger::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::ssh::generate_key {
  local \
    keytype="${TERMINATOR_SSH_DEFAULT_KEY_TYPE}" \
    suffix \
    verbose_flag \
    user \
    host \
    timestamp \
    keyfile \
    keygen_options=()

  user="$(whoami)"
  host="$(hostname -s)"
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::ssh::generate_key::usage
        return "${TERMINATOR_SSH_INVALID_STATUS}"
        ;;
      -t | --key-type)
        shift
        keytype="$1"
        ;;
      -s | --suffix)
        shift
        suffix="$1"
        ;;
      -v | -vv | -vvv)
        verbose_flag="$1"
        ;;
      *)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::ssh::generate_key::usage
        return "${TERMINATOR_SSH_INVALID_STATUS}"
        ;;
    esac
    shift
  done

  if [[ -z "${suffix}" ]]; then
    keyfile="${HOME}/.ssh/id_${keytype}"
  else
    keyfile="${HOME}/.ssh/id_${keytype}_${suffix}"
  fi

  keygen_options+=(
    -t "${keytype}"
    -C "${user}@${host}:${keyfile} -- ${timestamp}"
    -f "${keyfile}"
  )

  if [[ -n "${verbose_flag}" ]]; then
    keygen_options+=("${verbose_flag}")
  fi

  terminator::logger::info 'Generating ssh key using:'
  printf '  %s %s\n' "${keygen_options[@]}"

  ssh-keygen "${keygen_options[@]}"
}

function terminator::ssh::generate_key::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS]

  -t, --key-type     Key type
                     Default: ${TERMINATOR_SSH_DEFAULT_KEY_TYPE}

  -s, --suffix       Key suffix. If specified adds this to the keyfile name.

  -v, --vv, -vvv     Verbose mode.
                     Multiple -v options increase the verbosity
                     The maximum is 3.

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::ssh::__export__ {
  export -f terminator::ssh::is_ssh_session
  export -f terminator::ssh::ppinfo
  export -f terminator::ssh::is_ssh_sudo
  export -f terminator::ssh::find_keys
  export -f terminator::ssh::find_and_add_keys
  export -f terminator::ssh::add_key
  export -f terminator::ssh::add_key::os::darwin
  export -f terminator::ssh::add_key::os::linux
  export -f terminator::ssh::add_key::os::windows
  export -f terminator::ssh::add_key::os::unsupported
  export -f terminator::ssh::generate_key
  export -f terminator::ssh::generate_key::usage
}

function terminator::ssh::__recall__ {
  export -fn terminator::ssh::is_ssh_session
  export -fn terminator::ssh::ppinfo
  export -fn terminator::ssh::is_ssh_sudo
  export -fn terminator::ssh::find_keys
  export -fn terminator::ssh::find_and_add_keys
  export -fn terminator::ssh::add_key
  export -fn terminator::ssh::add_key::os::darwin
  export -fn terminator::ssh::add_key::os::linux
  export -fn terminator::ssh::add_key::os::windows
  export -fn terminator::ssh::add_key::os::unsupported
  export -fn terminator::ssh::generate_key
  export -fn terminator::ssh::generate_key::usage
}

terminator::__module__::export
