#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

function tmux::bootstrap::session_create() {
  local path

  if ! path="$(tmux::config::current_version::path)"; then
    tmux::log::error "skipping load of missing config: '${path}'"

    version="$(tmux::config::rollback_version)"
    path="$(tmux::config::rollback_version::path)"
    tmux::log::warning "reverting to version ${version} config: ${path}"
  fi

  tmux::bootstrap::styles
  tmux::bootstrap::build_session_created_messages

  TMUX_VERSION_CONFIG_PATH="${path}"
  TMUX_SESSION_CREATED_MESSAGES_PATH="$(tmux::bootstrap::messages::path)"

  export TMUX_VERSION_CONFIG_PATH
  export TMUX_SESSION_CREATED_MESSAGES_PATH
}

function tmux::bootstrap::styles() {
  # to add scripts use this format #(~/.tmux/bin/foobar.sh)
  export TMUX_HOST_COLOR="colour${HostColorNum}"
  export TMUX_BG_COLOR="colour234"
  export TMUX_SESSION_COLOR="colour10"
  export TMUX_MESSAGE_COLOR="colour16"
  export TMUX_MENU_COLOR="colour39"
  export TMUX_DIVIDER_RIGHT="#[fg=${TMUX_MENU_COLOR},bg=${TMUX_BG_COLOR}]⮂#[fg=${TMUX_BG_COLOR},bg=${TMUX_MENU_COLOR}]⮂#[fg=${TMUX_SESSION_COLOR},bg=${TMUX_BG_COLOR}]"
  export TMUX_DIVIDER_LEFT="#[fg=${TMUX_BG_COLOR},bg=${TMUX_MENU_COLOR}]⮀#[fg=${TMUX_MENU_COLOR},bg=${TMUX_BG_COLOR},nobold]⮀"
  export TMUX_PREFIX_STAT='#{?client_prefix,#[reverse]<Prefix>#[noreverse] , }'
  export TMUX_STATUS_RIGHT="#[fg=${TMUX_SESSION_COLOR},bg=${TMUX_BG_COLOR}]${TMUX_PREFIX_STAT}${TMUX_DIVIDER_RIGHT} %a %b %d %R #[default]"
  export TMUX_STATUS_LEFT="#[fg=${TMUX_SESSION_COLOR},bg=${TMUX_BG_COLOR}] #S #[fg=${TMUX_HOST_COLOR},bg=${TMUX_BG_COLOR}]#h ${TMUX_DIVIDER_LEFT} "
  export TMUX_STATUS=' #I #W '
  export TMUX_STATUS_CURRENT="#[fg=${TMUX_MESSAGE_COLOR},bg=${TMUX_MENU_COLOR},noreverse,bright,nobold] #I #W #[fg=${TMUX_MENU_COLOR},bg=${TMUX_BG_COLOR},nobold]"
}

function tmux::bootstrap::build_session_created_messages() {
  local input output
  input="$(tmux::log::path)"
  output="$(tmux::bootstrap::messages::path)"

  # skip if log is empty
  [[ -s "${input}" ]] || return 0

  cat > "${output}" <<-EOM
TMUX_SESSION_CREATED_MESSAGES='display-message -p "==================================================" ; \\
  display-message -p "tmux session-created messages:" ; \\
  display-message -p "=================================================="; \\
EOM

  while IFS= read -r line; do
    echo "  display-message -p \"${line}\" ; \\" >> "${output}"
  done < "${input}"

  cat >> "${output}" <<-EOM
  set-hook -gu session-created ;'
set-hook -g session-created \${TMUX_SESSION_CREATED_MESSAGES}
EOM
}

function tmux::bootstrap::messages::path() {
  # echo '/tmp/tmux-session-created.error.conf'
  local log_path
  log_path="$(tmux::log::path)"
  echo "${log_path/log/conf}"
}
