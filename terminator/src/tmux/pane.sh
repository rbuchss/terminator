#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
# TODO: add some more logging here?
# source "${BASH_SOURCE[0]%/*}/logger.sh"

terminator::__module__::load || return 0

function terminator::tmux::pane::toggle_pipe_to_log {
  local \
    default_log_path \
    pipe_status \
    session_window_pane_pattern

  # Check active pipe status
  pipe_status="$(tmux display-message -p "#{pane_pipe}")"

  if (( pipe_status > 0 )); then
    # Logging is ON; turn it off by removing the pipe
    session_window_pane_pattern="$(
      terminator::tmux::pane::session_window_pane_pattern
    )"

    tmux pipe-pane
    tmux display-message \
      "Stopped pipping log for pane: ${session_window_pane_pattern}"
  else
    # Logging is OFF; start logging
    default_log_path="$(terminator::tmux::pane::default_log_path 'tmux-pipe')"

    tmux command-prompt \
      -I "${default_log_path}" \
      -p "Pipe Pane to Log:" \
      "display-message 'Pipping pane log to: %1'; \
      pipe-pane -o 'cat >>%1'"
  fi
}

function terminator::tmux::pane::save_to_log {
  local default_log_path

  default_log_path="$(terminator::tmux::pane::default_log_path 'tmux-save')"

  tmux command-prompt \
    -I "${default_log_path}" \
    -p "Save Pane to Log:" \
    "capture-pane -S -; \
    save-buffer '%1'; \
    delete-buffer; \
    display-message 'Pane saved to: %1'"
}

function terminator::tmux::pane::session_window_pane_pattern {
  local \
    session="session-#{session_name}" \
    window="window-#{window_name}" \
    pane="pane-#{pane_index}"

  printf '%s.%s.%s' \
    "${session}" \
    "${window}" \
    "${pane}"
}

function terminator::tmux::pane::default_log_name {
  local \
    timestamp \
    log_type="${1:?}" \
    session_window_pane_pattern

  timestamp="$(date +%Y-%m-%dT%H-%M)"
  session_window_pane_pattern="$(
    terminator::tmux::pane::session_window_pane_pattern
  )"

  printf '%s.%s.%s.log' \
    "${timestamp}" \
    "${log_type}" \
    "${session_window_pane_pattern}"
}

function terminator::tmux::pane::default_log_path {
  # TODO: allow the log_directory to be set by env var?
  local \
    log_type="${1:?}" \
    log_directory="${2:-${TMUX_LOG_DIR:-${HOME}}}" \
    log_name

  log_name="$(terminator::tmux::pane::default_log_name "${log_type}")"

  printf '%s/%s' \
    "${log_directory}" \
    "${log_name}"
}

function terminator::tmux::pane::__export__ {
  export -f terminator::tmux::pane::toggle_pipe_to_log
  export -f terminator::tmux::pane::save_to_log
}

function terminator::tmux::pane::__recall__ {
  export -fn terminator::tmux::pane::toggle_pipe_to_log
  export -fn terminator::tmux::pane::save_to_log
}

terminator::__module__::export
