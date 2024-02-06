#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::tmuxinator::__enable__() {
  terminator::command::exists -v tmuxinator || return

  alias tmuxinator='terminator::tmuxinator::invoke'
  alias mux='terminator::tmuxinator::invoke'

  terminator::tmuxinator::completion::add_alias \
    'tmuxinator' \
    'mux'
}

function terminator::tmuxinator::__disable__() {
  unalias tmuxinator
  unalias mux

  terminator::tmuxinator::completion::remove_alias \
    'tmuxinator' \
    'mux'
}

function terminator::tmuxinator::invoke() {
  local recalled=0

  if [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.terminator/bin/tmux-session-create"

    # We need to remove exported log functions otherwise tmux will not be happy.
    terminator::__module__::recall terminator::log
    recalled=1
  fi

  command tmuxinator "$@"
  local exit_status=$?

  if (( recalled == 1 )); then
    # Re-init removed exported log functions.
    terminator::__module__::export terminator::log
  fi

  return "${exit_status}"
}

function terminator::tmuxinator::completion() {
  COMPREPLY=()
  local word
  word="${COMP_WORDS[COMP_CWORD]}"

  if [ "${COMP_CWORD}" -eq 1 ]; then
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "$(command tmuxinator commands)" -- "${word}")

    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "$(command tmuxinator completions start)" -- "${word}")
  elif [ "${COMP_CWORD}" -eq 2 ]; then
    local words
    words=("${COMP_WORDS[@]}")
    unset 'words[0]'
    unset words["${COMP_CWORD}"]
    local completions
    completions=$(command tmuxinator completions "${words[@]}")

    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "${completions}" -- "${word}")
  fi
}

function terminator::tmuxinator::completion::add_alias() {
  # complete -F _tmuxinator tmuxinator mux
  local name
  for name in "$@"; do
    complete -F terminator::tmuxinator::completion "${name}"
  done
}

function terminator::tmuxinator::completion::remove_alias() {
  local name
  for name in "$@"; do
    complete -r "${name}"
  done
}

function terminator::tmuxinator::__export__() {
  export -f terminator::tmuxinator::invoke
  export -f terminator::tmuxinator::completion
  export -f terminator::tmuxinator::completion::add_alias
  export -f terminator::tmuxinator::completion::remove_alias
}

function terminator::tmuxinator::__recall__() {
  export -fn terminator::tmuxinator::invoke
  export -fn terminator::tmuxinator::completion
  export -fn terminator::tmuxinator::completion::add_alias
  export -fn terminator::tmuxinator::completion::remove_alias
}

terminator::__module__::export
