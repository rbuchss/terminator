#!/bin/bash

function terminator::ssh::is_ssh_session() {
  [[ -n "${SSH_CLIENT}" ]] \
    || [[ -n "${SSH_TTY}" ]] \
    || terminator::ssh::is_ssh_sudo "$@"
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
