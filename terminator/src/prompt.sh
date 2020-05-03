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
  local last_command_exit=$? \
    error_status \
    ssh_status \
    user \
    user_separator \
    host \
    directory \
    version_control \
    newline \
    command_symbol \
    color_off

  terminator::prompt::error "${last_command_exit}" error_status
  terminator::prompt::ssh ssh_status
  terminator::prompt::user user
  terminator::styles::user_separator user_separator
  terminator::prompt::host host
  terminator::prompt::directory directory
  terminator::prompt::version_control version_control
  terminator::styles::newline newline
  terminator::styles::command_symbol command_symbol
  terminator::color::off color_off

  printf -v PS1 '%s%s%s%s%s %s %s %s%s %s' \
    "${error_status}" \
    "${ssh_status}" \
    "${user}" \
    "${user_separator}" \
    "${host}" \
    "${directory}" \
    "${version_control}" \
    "${newline}" \
    "${command_symbol}" \
    "${color_off}"
  export PS1
}

function terminator::prompt::error() {
  local last_command_exit="${1:-$?}"

  if (( last_command_exit != 0 )); then
    local error_color error_symbol

    terminator::styles::error_color error_color
    terminator::styles::error_symbol error_symbol

    case "$#" in
      2)
        printf -v "$2" '%s%s ' \
          "${error_color}" \
          "${error_symbol}"
        ;;
      *)
        printf '%s%s ' \
          "${error_color}" \
          "${error_symbol}"
        ;;
    esac
  fi
}

function terminator::prompt::ssh() {
  # TODO cache this value
  if declare -F terminator::ssh::is_ssh_session > /dev/null \
    && terminator::ssh::is_ssh_session; then
      local host_color host_symbol

      terminator::styles::host_color host_color
      terminator::styles::host_symbol host_symbol

      case "$#" in
        1)
          printf  -v "1" '%s%s ' \
            "${host_color}" \
            "${host_symbol}"
          ;;
        *)
          printf '%s%s ' \
            "${host_color}" \
            "${host_symbol}"
          ;;
      esac
    return
  fi
}

function terminator::prompt::user() {
  local user_color username

  terminator::styles::user_color user_color
  terminator::styles::username username

  case "$#" in
    1)
      printf -v "$1" '%s%s' \
        "${user_color}" \
        "${username}"
      ;;
    *)
      printf '%s%s' \
        "${user_color}" \
        "${username}"
      ;;
  esac
}

function terminator::prompt::host() {
  local host_color hostname

  terminator::styles::host_color host_color
  terminator::styles::hostname hostname

  case "$#" in
    1)
      printf -v "$1" '%s%s' \
        "${host_color}" \
        "${hostname}"
      ;;
    *)
      printf '%s%s' \
        "${host_color}" \
        "${hostname}"
      ;;
  esac
}

function terminator::prompt::directory() {
  local path_color path

  terminator::styles::path_color path_color
  terminator::styles::path path

  case "$#" in
    1)
      printf -v "$1" '%s%s' \
        "${path_color}" \
        "${path}"
      ;;
    *)
      printf '%s%s' \
        "${path_color}" \
        "${path}"
      ;;
  esac
}

function terminator::prompt::version_control() {
  local svn_status git_status

  # terminator::prompt::svn svn_status
  terminator::prompt::git git_status

  case "$#" in
    1)
      printf -v "$1" '%s%s' \
        "${svn_status}" \
        "${git_status}"
      ;;
    *)
      printf '%s%s' \
        "${svn_status}" \
        "${git_status}"
      ;;
  esac
}
