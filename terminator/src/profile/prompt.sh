#!/bin/bash

function terminator::profile::prompt::svn_info() {
  # svn info
  stat .svn > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    SURL=`svn info | grep URL | head -1 | perl -pe 's/URL: (.*)/\1/'`
    if [ `echo $SURL | grep -E "branches|tags"` ]; then
      SVER=`echo $SURL \
        | perl -pe 's{.*/(branches|tags)/(.*)}{\1/\2}' | cut -d/ -f1-2`
      SPTH=`echo $SURL \
        | perl -pe 's{.*svnroot/(.*)/(branches|tags)/.*}{/\1}'`
      SPWD="$SPTH/$SVER"
      SCL=$IGreen
    else
      SPWD=`echo $SURL \
        | perl -pe 's{.*svnroot/(.*)/trunk(.*)}{/\1/trunk}'`
      SCL=$IYellow
    fi
    svn status | egrep '.+' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      SCL=$IRed
    fi
    echo "${SCL}[SVN: $SPWD]"
  else
    echo ''
  fi
}

function terminator::profile::prompt::git_info() {
  # git info
  git branch >/dev/null 2>&1 && command -v __git_ps1 >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    GitBranch=`__git_ps1 "%s"`
    if [[ $GitBranch =~ ^\( ]]; then
      char=$detached_head_char
    else
      char=$branch_char
    fi
    git status | grep "nothing to commit" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      # Clean repository - nothing to commit
      clean_color="$(color_code "38;5;10m")"
      echo "${clean_color}$char $GitBranch $check_char$ColorOff"
    else
      git status | egrep '(Changes to be committed|Changes not staged for commit)' >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        # Changes to working tree
        dirty_color="$(color_code "38;5;9m")"
        echo "${dirty_color}$char $GitBranch $x_char$ColorOff"
      else
        dirty_color="$(color_code "38;5;214m")"
        echo "${dirty_color}$char $GitBranch $x_char$ColorOff"
      fi
    fi
  else
    echo ''
  fi
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
