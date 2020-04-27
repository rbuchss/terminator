#!/bin/bash

function terminator::ssh::is_ssh_session() {
  [[ -n "${SSH_CLIENT}" ]] \
    || [[ -n "${SSH_TTY}" ]] \
    || terminator::ssh::is_ssh_sudo "$@" # TODO is this really required?
}

function terminator::ssh::ppid() {
  ps -p "${1:-$$}" -o ppid=
}

function terminator::ssh::ppinfo() {
  ps -p "${1:-$$}" -o ppid= -o user= -o comm=
}

function terminator::ssh::is_ssh_sudo() {
  user="$(logname)"
  ppid="$(terminator::ssh::ppid "${1:-$$}")"
  is_ssh="$(terminator::ssh::ppinfo "${1:-$$}" | command grep "${user} sshd")"

  if [[ -n "${is_ssh}" ]]; then
    return 0
  elif [[ -z "${ppid}" ]] || [[ "${ppid}" -eq 0 ]]; then
    return 1
  fi

  terminator::ssh::is_ssh_sudo "${ppid}"
}
