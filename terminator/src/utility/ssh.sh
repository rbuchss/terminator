#!/bin/bash

function terminator::utility::ssh::is_ssh_session() {
  [[ -n "${SSH_CLIENT}" ]] \
    || [[ -n "${SSH_TTY}" ]] \
    || terminator::utility::ssh::is_ssh_sudo "$@"
}

function terminator::utility::ssh::ppid() {
  ps -p "${1:-$$}" -o ppid=
}

function terminator::utility::ssh::ppinfo() {
  ps -p "${1:-$$}" -o ppid= -o user= -o comm=
}

function terminator::utility::ssh::is_ssh_sudo() {
  user="$(logname)"
  ppid="$(terminator::utility::ssh::ppid "${1:-$$}")"
  is_ssh="$(terminator::utility::ssh::ppinfo "${1:-$$}" | grep "${user} sshd")"

  if [[ -n "${is_ssh}" ]]; then
    return 0
  elif [[ -z "${ppid}" ]] || [[ "${ppid}" -eq 0 ]]; then
    return 1
  fi

  is_ssh_sudo "${ppid}"
}
