#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/ssh.sh"
source "${BASH_SOURCE[0]%/*}/styles.sh"
source "${BASH_SOURCE[0]%/*}/prompt/git.sh"
source "${BASH_SOURCE[0]%/*}/prompt/svn.sh"

# Customize BASH PS1 prompt to show current
# GIT or SVN repository and branch
# along with colorization to show status
# (red dirty/green clean)
function terminator::prompt() {
  local last_command_exit=$?
  printf -v PS1 '%s%s%s%s%s %s %s %s%s %s' \
    "$(terminator::prompt::error "${last_command_exit}")" \
    "$(terminator::prompt::ssh)" \
    "$(terminator::prompt::user)" \
    "$(terminator::styles::user_separator)" \
    "$(terminator::prompt::host)" \
    "$(terminator::prompt::directory)" \
    "$(terminator::prompt::version_control)" \
    "$(terminator::styles::newline)" \
    "$(terminator::styles::command_symbol)" \
    "$(terminator::color::off)"
  export PS1
}

function terminator::prompt::error() {
  local last_command_exit="${1:-$?}"

  if (( $# > 1 )); then
    >&2 echo "ERROR: invalid number of arguments"
    >&2 echo "Usage: ${FUNCNAME[0]} [last_command_exit] # defaults to \$?"
    return 1
  fi

  if (( last_command_exit == 0 )); then
    echo ''
    return
  fi

  printf '%s%s ' \
    "$(terminator::styles::error_color)" \
    "$(terminator::styles::error_symbol)"
}

function terminator::prompt::ssh() {
  if declare -F terminator::ssh::is_ssh_session > /dev/null \
    && terminator::ssh::is_ssh_session; then
    printf '%s%s ' \
      "$(terminator::styles::host_color)" \
      "$(terminator::styles::host_symbol)"
    return
  fi

  echo ''
}

function terminator::prompt::user() {
  printf '%s%s' \
    "$(terminator::styles::user_color)" \
    "$(terminator::styles::username)"
}

function terminator::prompt::host() {
  printf '%s%s' \
    "$(terminator::styles::host_color)" \
    "$(terminator::styles::hostname)"
}

function terminator::prompt::directory() {
  printf '%s%s' \
    "$(terminator::styles::path_color)" \
    "$(terminator::styles::path)"
}

function terminator::prompt::version_control() {
  printf '%s%s' \
    "$(terminator::prompt::svn)" \
    "$(terminator::prompt::git)"
}
