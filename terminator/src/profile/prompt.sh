#!/bin/bash

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/utility/ssh.sh"
source "${BASH_SOURCE[0]%/*}/styles.sh"

function terminator::profile::prompt::svn_info() {
  local url version path working_path color

  if stat .svn > /dev/null 2>&1; then
    if ! command -v svn > /dev/null 2>&1; then
      echo ''
      return 0
    fi

    url="$(svn info | grep 'URL' | head -1 | perl -pe 's/URL: (.*)/\1/')"

    if grep -q -E 'branches|tags' <<< "${url}"; then
      version="$(echo "${url}" \
        | perl -pe 's{.*/(branches|tags)/(.*)}{\1/\2}' \
        | cut -d/ -f1-2)"
      path="$(echo "${url}" \
        | perl -pe 's{.*svnroot/(.*)/(branches|tags)/.*}{/\1}')"
      working_path="${path}/${version}"
      color="$(terminator::profile::styles::ok_color)"
    else
      working_path="$(echo "${url}" \
        | perl -pe 's{.*svnroot/(.*)/trunk(.*)}{/\1/trunk}')"
      color="$(terminator::profile::styles::warning_color)"
    fi

    if svn status | grep -q -E '.+'; then
      color="$(terminator::profile::styles::error_color)"
    fi

    echo "${color}[SVN: ${working_path}]"
    return 0
  fi

  echo ''
}

function terminator::profile::prompt::git_info() {
  if ! command -v git > /dev/null 2>&1 \
    || ! command -v __git_ps1 > /dev/null 2>&1; then
    echo ''
    return 0
  fi

  local inside_worktree branch branch_symbol color status_symbol
  local color_off
  color_off="$(terminator::styles::color::off)"

  if inside_worktree="$(git rev-parse --is-inside-work-tree 2>/dev/null)"; then
    branch="$(__git_ps1 '%s')"
    branch_symbol="$(terminator::profile::styles::branch_symbol)"

    if [[ "${branch}" =~ ^\( ]]; then
      branch_symbol="$(terminator::profile::styles::detached_head_symbol)"
    fi

    if [[ "${inside_worktree}" != 'true' ]]; then
      echo "${branch_symbol} ${branch}${color_off}"
      return 0
    fi

    if [[ -z "$(git status --porcelain)" ]]; then
      # Clean repository - nothing to commit
      color="$(terminator::profile::styles::ok_color)"
      status_symbol="$(terminator::profile::styles::ok_symbol)"
    elif ! (git diff --no-ext-diff --cached --quiet --exit-code \
      && git diff --no-ext-diff --quiet --exit-code); then
      # Changes exist on working tree
      color="$(terminator::profile::styles::error_color)"
      status_symbol="$(terminator::profile::styles::error_symbol)"
    else
      # Untracked files exist
      color="$(terminator::styles::color::code '38;5;214m')"
      status_symbol="$(terminator::profile::styles::warning_symbol)"
    fi

    echo "${color}${branch_symbol} ${branch} ${status_symbol}${color_off}"
    return 0
  fi

  echo ''
}

function terminator::profile::prompt::ssh_info() {
  if declare -F terminator::utility::ssh::is_ssh_session > /dev/null \
    && terminator::utility::ssh::is_ssh_session; then
    local host_color host_symbol
    host_color="$(terminator::profile::styles::host_color)"
    host_symbol="$(terminator::profile::styles::host_symbol)"
    echo "${host_color}${host_symbol} "
    return 0
  fi

  echo ''
}

function terminator::profile::prompt::user_info() {
  local username user_color
  username="$(terminator::profile::styles::username)"
  user_color="$(terminator::profile::styles::user_color)"
  echo "${user_color}${username}"
}

function terminator::profile::prompt::host_info() {
  local hostname host_color
  hostname="$(terminator::profile::styles::hostname)"
  host_color="$(terminator::profile::styles::host_color)"
  echo "${host_color}${hostname}"
}

function terminator::profile::prompt::pwd_info() {
  local path path_color
  path="$(terminator::profile::styles::path)"
  path_color="$(terminator::profile::styles::path_color)"
  echo "${path_color}${path}"
}

function terminator::profile::prompt::basic_info() {
  local user_info user_separator host_info pwd_info
  user_info="$(terminator::profile::prompt::user_info)"
  user_separator="$(terminator::profile::styles::user_separator)"
  host_info="$(terminator::profile::prompt::host_info)"
  pwd_info="$(terminator::profile::prompt::pwd_info)"
  echo "${user_info}${user_separator}${host_info} ${pwd_info}"
}

function terminator::profile::prompt::vcs_info() {
  local svn_info git_info
  svn_info="$(terminator::profile::prompt::svn_info)"
  git_info="$(terminator::profile::prompt::git_info)"
  echo "${svn_info}${git_info}"
}

function terminator::profile::prompt::base_info() {
  local ssh_info basic_info vcs_info
  ssh_info="$(terminator::profile::prompt::ssh_info)"
  basic_info="$(terminator::profile::prompt::basic_info)"
  vcs_info="$(terminator::profile::prompt::vcs_info)"
  echo "${ssh_info}${basic_info} ${vcs_info}"
}

function terminator::profile::prompt::error_info() {
  local last_command_exit="${1:-$?}"

  if (( $# > 1 )); then
    >&2 echo "ERROR: invalid number of arguments"
    >&2 echo "Usage: ${FUNCNAME[0]} [last_command_exit] # defaults to \$?"
    return 1
  fi

  if [[ "${last_command_exit}" -eq 0 ]]; then
    echo ''
    return 0
  fi

  local error_symbol error_color
  error_symbol="$(terminator::profile::styles::error_symbol)"
  error_color="$(terminator::profile::styles::error_color)"
  echo "${error_color}${error_symbol} "
}

function terminator::profile::prompt::suffix_info() {
  local newline command_symbol color_off
  newline="$(terminator::styles::newline)"
  command_symbol="$(terminator::profile::styles::command_symbol)"
  color_off="$(terminator::styles::color::off)"
  echo "${newline}${command_symbol} ${color_off}"
}

# Customize BASH PS1 prompt to show current
# GIT or SVN repository and branch
# along with colorization to show status
# (red dirty/green clean)
function terminator::profile::prompt() {
  local last_command_exit=$?
  local error_info base_info suffix_info
  error_info="$(terminator::profile::prompt::error_info "${last_command_exit}")"
  base_info="$(terminator::profile::prompt::base_info)"
  suffix_info="$(terminator::profile::prompt::suffix_info)"
  export PS1="${error_info}${base_info} ${suffix_info}"
}
