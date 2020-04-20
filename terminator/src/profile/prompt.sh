#!/bin/bash

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
      color="${IGreen}"
    else
      working_path="$(echo "${url}" \
        | perl -pe 's{.*svnroot/(.*)/trunk(.*)}{/\1/trunk}')"
      color="${IYellow}"
    fi

    if svn status | grep -q -E '.+'; then
      color="${IRed}"
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

  if inside_worktree="$(git rev-parse --is-inside-work-tree 2>/dev/null)"; then
    branch="$(__git_ps1 '%s')"
    branch_symbol="${branch_char}"

    if [[ "${branch}" =~ ^\( ]]; then
      branch_symbol="${detached_head_char}"
    fi

    if [[ "${inside_worktree}" != 'true' ]]; then
      echo "${branch_symbol} ${branch}${ColorOff}"
      return 0
    fi

    if [[ -z "$(git status --porcelain)" ]]; then
      # Clean repository - nothing to commit
      color="$(color_code "38;5;10m")"
      status_symbol="${check_char}"
    elif ! (git diff --no-ext-diff --cached --quiet --exit-code \
      || git diff --no-ext-diff --quiet --exit-code); then
      # Changes exist on working tree
      color="$(color_code "38;5;9m")"
      status_symbol="${x_char}"
    else
      # Untracked files exist
      color="$(color_code "38;5;214m")"
      status_symbol="${x_char}"
    fi

    echo "${color}${branch_symbol} ${branch} ${status_symbol}${ColorOff}"
    return 0
  fi

  echo ''
}

function terminator::profile::prompt::ssh_info() {
  if is_ssh_session; then
    echo "${HostColor}${HostChar} "
    return 0
  fi

  echo ''
}

function terminator::profile::prompt::user_info() {
  echo "${UserColor}${UserName}"
}

function terminator::profile::prompt::host_info() {
  echo "${HostColor}${HostName}"
}

function terminator::profile::prompt::pwd_info() {
  echo "${PathColor}${PathFull}"
}

function terminator::profile::prompt::basic_info() {
  local user_info host_info pwd_info
  user_info="$(terminator::profile::prompt::user_info)"
  host_info="$(terminator::profile::prompt::host_info)"
  pwd_info="$(terminator::profile::prompt::pwd_info)"
  echo "${user_info}${UserSeparator}${host_info} ${pwd_info}"
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

  echo "${IRed}${x_char} "
}

function terminator::profile::prompt::suffix_info() {
  echo "${NewLine}${arrow_char} ${ColorOff}"
}

# Customize BASH PS1 prompt to show current
# GIT or SVN repository and branch
# along with colorization to show status
# (red dirty/green clean)
#
# NOTE: terminator::profile::prompt::error_info
#   must be run first to properly capture if
#   last command had non-zero exit status
function terminator::profile::prompt() {
  local last_command_exit=$?
  local error_info base_info suffix_info
  error_info="$(terminator::profile::prompt::error_info "${last_command_exit}")"
  base_info="$(terminator::profile::prompt::base_info)"
  suffix_info="$(terminator::profile::prompt::suffix_info)"
  export PS1="${error_info}${base_info} ${suffix_info}"
}
