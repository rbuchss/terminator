#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::git::__enable__ {
  terminator::command::exists -v git || return

  alias git='terminator::git::invoke'
  alias g='terminator::git::invoke'

  __git_complete g __git_main
}

function terminator::git::__disable__ {
  unalias git
  unalias g

  # __git_complete uses complete under the hood so using
  #   complete -r to remove
  # ref:
  #   https://github.com/git/git/blob/e79552d19784ee7f4bbce278fe25f93fbda196fa/contrib/completion/git-completion.bash#L3741-L3747
  complete -r g
}

function terminator::git::invoke {
  if terminator::command::exists hub; then
    command hub "$@"
    return
  fi

  command git "$@"
}

function terminator::git::__export__ {
  export -f terminator::git::invoke
}

function terminator::git::__recall__ {
  export -fn terminator::git::invoke
}

terminator::__module__::export
