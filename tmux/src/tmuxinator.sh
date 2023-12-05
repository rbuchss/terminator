#!/bin/bash

function tmux::tmuxinator::bootstrap() {
  alias tmuxinator='tmux::tmuxinator::command::invoke'
  alias mux='tmux::tmuxinator::command::invoke'

  tmux::tmuxinator::completion::add_alias \
    'tmuxinator' \
    'mux'
}

function tmux::tmuxinator::command::invoke() {
  local recalled=0

  if [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.tmux/bin/session-create"

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

function tmux::tmuxinator::completion() {
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

function tmux::tmuxinator::completion::add_alias() {
  # complete -F _tmuxinator tmuxinator mux
  for name in "$@"; do
    complete -F tmux::tmuxinator::completion tmuxinator "${name}"
  done
}
