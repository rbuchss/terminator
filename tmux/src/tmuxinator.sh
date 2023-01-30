#!/bin/bash

function tmuxinator::command::invoke() {
  if [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.tmux/bin/session-create"
  fi
  command tmuxinator "$@"
}

function tmux::tmuxinator::completion() {
  COMPREPLY=()
  local word
  word="${COMP_WORDS[COMP_CWORD]}"

  if [ "${COMP_CWORD}" -eq 1 ]; then
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "$(tmuxinator commands)" -- "${word}")

    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "$(tmuxinator completions start)" -- "${word}")
  elif [ "${COMP_CWORD}" -eq 2 ]; then
    local words
    words=("${COMP_WORDS[@]}")
    unset 'words[0]'
    unset words["${COMP_CWORD}"]
    local completions
    completions=$(tmuxinator completions "${words[@]}")

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
