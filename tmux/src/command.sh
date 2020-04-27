#!/bin/bash

function tmux::command::invoke() {
  # shellcheck disable=SC2154
  if (( $# == 0 )) && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.tmux/bin/session-create.sh"
  fi
  command tmux "$@"
}
