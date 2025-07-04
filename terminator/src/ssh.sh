#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"
source "${BASH_SOURCE[0]%/*}/os.sh"

terminator::__module__::load || return 0

function terminator::ssh::__enable__ {
  alias ssh-init='terminator::ssh::find_and_add_keys'
}

function terminator::ssh::__disable__ {
  unalias ssh-init
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
  local regexp='^([[:digit:]]+)[[:space:]]+(sshd: (.*))?'
  local ppinfo ppid ssh_user
  ppinfo="$(terminator::ssh::ppinfo "${1:-$$}")"

  if [[ "${ppinfo}" =~ $regexp ]]; then
    ppid="${BASH_REMATCH[1]}"
    ssh_user="${BASH_REMATCH[3]}"

    # echo "ppid: '${ppid}' ssh_user: '${ssh_user}'"

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

  if ! command -v fzf > /dev/null 2>&1; then
    terminator::log::error 'Requires fzf which was not found - Exiting'
    return 1
  fi

  while IFS= read -r ssh_key_path; do
    ssh_key_paths+=("${ssh_key_path}")
  done < <(terminator::ssh::find_keys | fzf --multi --header='Select ssh keys to add')

  if (( ${#ssh_key_paths[@]} == 0 )); then
    terminator::log::warning 'No ssh keys found - Exiting'
    return 1
  fi

  terminator::log::info "Selected ssh keys: [${ssh_key_paths[*]}]"

  for ssh_key_path in "${ssh_key_paths[@]}"; do
    terminator::ssh::add_key "${ssh_key_path}"
  done
}

function terminator::ssh::add_key {
  local ssh_key_path="${1:?}"

  if [[ ! -f "${ssh_key_path}" ]]; then
    terminator::log::warning "Cannot find ssh private key: '${ssh_key_path}' - Exiting"
    return 1
  fi

  if [[ ! -f "${ssh_key_path}.pub" ]]; then
    terminator::log::warning "Cannot find ssh public key: '${ssh_key_path}.pub' - Exiting"
    return 1
  fi

  # Check if public key already exists in ssh authentication agent - if so just noop
  if command ssh-add -L | command grep -q -f "${ssh_key_path}.pub"; then
    terminator::log::info "ssh-identity '${ssh_key_path}' found in authentication agent - Noop"
    return
  fi

  terminator::log::info "ssh-identity '${ssh_key_path}' NOT found in authentication agent - Adding"

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

    terminator::log::warning "Cannot find ssh-add darwin default at: '${ssh_add_path_for_darwin}' - Falling back to first in PATH: '${ssh_add_fallback_path}'"

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
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
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
}

terminator::__module__::export
