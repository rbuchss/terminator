#!/bin/bash

function terminator::ssh::is_ssh_session() {
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

function terminator::ssh::ppinfo() {
  command ps -p "${1:-$$}" -o ppid= -o comm=
}

function terminator::ssh::is_ssh_sudo() {
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
