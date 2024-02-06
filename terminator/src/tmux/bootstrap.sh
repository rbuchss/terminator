#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

terminator::__module__::load || return 0

function terminator::tmux::bootstrap::session_create() {
  local path version

  if ! path="$(terminator::tmux::config::current_version::path)"; then
    terminator::tmux::log::error "skipping load of missing config: '${path}'"

    if version="$(terminator::tmux::config::rollback_version)"; then
      path="$(terminator::tmux::config::version::path "${version}")"
      terminator::tmux::log::warning "reverting to version ${version} config: ${path}"
    fi
  fi

  terminator::tmux::bootstrap::styles
  terminator::tmux::bootstrap::build_messages

  TMUX_VERSION_CONFIG_PATH="${path}"
  TMUX_BOOTSTRAP_MESSAGES_PATH="$(terminator::tmux::bootstrap::messages::path)"

  export TMUX_VERSION_CONFIG_PATH
  export TMUX_BOOTSTRAP_MESSAGES_PATH
}

function terminator::tmux::bootstrap::styles() {
  terminator::tmux::config::load 'styles.sh'
}

function terminator::tmux::bootstrap::build_messages() {
  local input output
  input="$(terminator::tmux::log::path)"
  output="$(terminator::tmux::bootstrap::messages::path)"

  # skip if log is empty
  [[ -s "${input}" ]] || return 0

  cat > "${output}" <<-EOM
TMUX_BOOTSTRAP_MESSAGES='display-message -p "==================================================" ; \\
  display-message -p "tmux session-created messages:" ; \\
  display-message -p "=================================================="; \\
EOM

  while IFS='' read -r line; do
    echo "  display-message -p \"${line}\" ; \\" >> "${output}"
  done < "${input}"

  cat >> "${output}" <<-EOM
  set-hook -gu session-created ;'
set-hook -g session-created \${TMUX_BOOTSTRAP_MESSAGES}
EOM
}

function terminator::tmux::bootstrap::messages::path() {
  local log_path
  log_path="$(terminator::tmux::log::path)"
  echo "${log_path/log/conf}"
}

function terminator::tmux::bootstrap::__export__() {
  export -f terminator::tmux::bootstrap::session_create
  export -f terminator::tmux::bootstrap::styles
  export -f terminator::tmux::bootstrap::build_messages
  export -f terminator::tmux::bootstrap::messages::path
}

function terminator::tmux::bootstrap::__recall__() {
  export -fn terminator::tmux::bootstrap::session_create
  export -fn terminator::tmux::bootstrap::styles
  export -fn terminator::tmux::bootstrap::build_messages
  export -fn terminator::tmux::bootstrap::messages::path
}

terminator::__module__::export
