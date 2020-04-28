#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

function tmux::bootstrap::session_create() {
  local path version

  if ! path="$(tmux::config::current_version::path)"; then
    tmux::log::error "skipping load of missing config: '${path}'"

    if version="$(tmux::config::rollback_version)"; then
      path="$(tmux::config::version::path "${version}")"
      tmux::log::warning "reverting to version ${version} config: ${path}"
    fi
  fi

  tmux::bootstrap::styles
  tmux::bootstrap::build_messages

  TMUX_VERSION_CONFIG_PATH="${path}"
  TMUX_BOOTSTRAP_MESSAGES_PATH="$(tmux::bootstrap::messages::path)"

  export TMUX_VERSION_CONFIG_PATH
  export TMUX_BOOTSTRAP_MESSAGES_PATH
}

function tmux::bootstrap::styles() {
  tmux::config::load 'styles.sh'
}

function tmux::bootstrap::build_messages() {
  local input output
  input="$(tmux::log::path)"
  output="$(tmux::bootstrap::messages::path)"

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

function tmux::bootstrap::messages::path() {
  local log_path
  log_path="$(tmux::log::path)"
  echo "${log_path/log/conf}"
}
