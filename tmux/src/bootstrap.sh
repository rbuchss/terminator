#!/bin/bash

function tmux::bootstrap::config_path() {
  if [ $# -eq 0 ]; then
    echo "$TMUX_CONFIG_PATH"
    return 0
  fi

  local result="$TMUX_CONFIG_PATH"
  for subpath in "$@"; do
    result="${result}/${subpath}"
  done
  echo "$result"
}

function tmux::bootstrap::version() {
  command tmux -V | grep -E -o '([0-9.]+)'
}

function tmux::bootstrap::session_create() {
  tmux::bootstrap::log::error::delete
  tmux::bootstrap::load_style_environment_vars

  local version_config_path
  version_config_path=$(tmux::bootstrap::version_config_path)

  if [ -z "$version_config_path" ]; then
    tmux::bootstrap::error "value for TMUX_VERSION_CONFIG_PATH is not set!"
    tmux::bootstrap::error "skipped load of $(tmux::bootstrap::config_path 'version')/<VERSION>/__init__.config"
    version_config_path=$(tmux::bootstrap::latest_version_config_path)
    tmux::bootstrap::warning "reverting to latest version config at: $version_config_path"
    tmux::bootstrap::build_session_created_error_messages
    TMUX_SESSION_CREATED_ERROR_MESSAGES_PATH=$(tmux::bootstrap::error::messages::path)
    export TMUX_SESSION_CREATED_ERROR_MESSAGES_PATH
  fi

  export TMUX_VERSION_CONFIG_PATH="$version_config_path"
}

function tmux::bootstrap::load_style_environment_vars() {
  # to add scripts use this format #(~/.tmux/helpers/battery-health.sh)
  export TmuxHostColor="colour${HostColorNum}"
  export TmuxBgColor="colour234"
  export TmuxSessionColor="colour10"
  export TmuxMessageColor="colour16"
  export TmuxMenuColor="colour39"

  export TMUX_DIVIDER_RIGHT="#[fg=${TmuxMenuColor},bg=${TmuxBgColor}]⮂#[fg=${TmuxBgColor},bg=${TmuxMenuColor}]⮂#[fg=${TmuxSessionColor},bg=${TmuxBgColor}]"
  export TMUX_DIVIDER_LEFT="#[fg=${TmuxBgColor},bg=${TmuxMenuColor}]⮀#[fg=${TmuxMenuColor},bg=${TmuxBgColor},nobold]⮀"
  export TMUX_PREFIX_STAT='#{?client_prefix,#[reverse]<Prefix>#[noreverse] , }'
  export TMUX_STATUS_RIGHT="#[fg=${TmuxSessionColor},bg=${TmuxBgColor}]${TMUX_PREFIX_STAT}${TMUX_DIVIDER_RIGHT} %a %b %d %R #[default]"
  export TMUX_STATUS_LEFT="#[fg=${TmuxSessionColor},bg=${TmuxBgColor}] #S #[fg=${TmuxHostColor},bg=${TmuxBgColor}]#h $TMUX_DIVIDER_LEFT "
  export TMUX_STATUS=' #I #W '
  export TMUX_STATUS_CURRENT="#[fg=${TmuxMessageColor},bg=${TmuxMenuColor},noreverse,bright,nobold] #I #W #[fg=${TmuxMenuColor},bg=${TmuxBgColor},nobold]"
}

function tmux::bootstrap::version_config_path() {
  local version_config_path
  version_config_path=$(tmux::bootstrap::config_path 'version' "$(tmux::bootstrap::version)")

  if [ ! -d "$version_config_path" ]; then
    tmux::bootstrap::error "config directory: '$version_config_path' does not exist!"
    return 1
  fi

  echo "$version_config_path"
}

function tmux::bootstrap::latest_version_config() {
  local versions_config_path
  versions_config_path=$(tmux::bootstrap::config_path 'version')
  # shellcheck disable=SC2012
  ls "$versions_config_path" | sort -V | tail -1
}

function tmux::bootstrap::latest_version_config_path() {
  tmux::bootstrap::config_path 'version' "$(tmux::bootstrap::latest_version_config)"
}

function tmux::bootstrap::build_session_created_error_messages() {
  local input output
  input=$(tmux::bootstrap::log::error::path)
  output=$(tmux::bootstrap::error::messages::path)

  echo "SESSION_CREATED_ERRORS='display-message -p \"tmux session-created: has errors/warnings\" ; \\" > "$output"

  while read -r line; do
    echo "display-message -p \"$line\" ; \\" >> "$output"
  done < "$input"

  cat >> "$output" <<-EOM
  set-hook -gu session-created ;'
  set-hook -g session-created \${SESSION_CREATED_ERRORS}
EOM
}

function tmux::bootstrap::error::messages::path() {
  echo '/tmp/tmux-session-created.error.conf'
}

function tmux::bootstrap::info() {
  local caller_level=2
  tmux::bootstrap::log::info -c "$caller_level" "$@"
  tmux::bootstrap::console::info -c "$caller_level" "$@"
}

function tmux::bootstrap::warning() {
  local caller_level=2
  tmux::bootstrap::log::warning -c "$caller_level" "$@"
  tmux::bootstrap::console::warning -c "$caller_level" "$@"
}

function tmux::bootstrap::error() {
  local caller_level=2
  tmux::bootstrap::log::error -c "$caller_level" "$@"
  tmux::bootstrap::console::error -c "$caller_level" "$@"
}

function tmux::bootstrap::console::info() {
  tmux::bootstrap::logger -l info -o /dev/stdout "$@"
}

function tmux::bootstrap::console::warning() {
  tmux::bootstrap::logger -l warning "$@"
}

function tmux::bootstrap::console::error() {
  tmux::bootstrap::logger -l error "$@"
}

function tmux::bootstrap::log::info() {
  local info_log
  info_log=$(tmux::bootstrap::log::info::path)
  tmux::bootstrap::logger -l info -o "$info_log" "$@"
}

function tmux::bootstrap::log::warning() {
  local warning_log
  warning_log=$(tmux::bootstrap::log::warning::path)
  tmux::bootstrap::logger -l warning -o "$warning_log" "$@"
}

function tmux::bootstrap::log::error() {
  local error_log
  error_log=$(tmux::bootstrap::log::error::path)
  tmux::bootstrap::logger -l error -o "$error_log" "$@"
}

function tmux::bootstrap::log::info::path() {
  echo '/tmp/tmux-session-created.info.log'
}

function tmux::bootstrap::log::warning::path() {
  tmux::bootstrap::log::error::path
}

function tmux::bootstrap::log::error::path() {
  echo '/tmp/tmux-session-created.error.log'
}

function tmux::bootstrap::log::error::delete() {
  local error_log
  error_log=$(tmux::bootstrap::log::error::path)
  rm -f "$error_log"
}

function tmux::bootstrap::logger() (
  function usage() {
    >&2 echo "Usage: ${FUNCNAME[1]} [-clo] # prints error message with caller info"
    >&2 echo "    -c: caller level (default: 0)"
    >&2 echo "    -o: output (default: /dev/stderr)"
  }

  local OPTIND flag
  local level='info'
  local caller_level=1
  local output=/dev/stderr

  while getopts 'c:l:o:' flag; do
    case "${flag}" in
      c) caller_level="${OPTARG}" ;;
      l) level="${OPTARG}" ;;
      o) output="${OPTARG}" ;;
      *) usage
        return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  local caller_info
  caller_info=$(tmux::bootstrap::caller_formatter "$(caller "$caller_level")")

  local level_prefix
  case "${level}" in
    info) level_prefix="INFO" ;;
    warning) level_prefix="WARNING" ;;
    *) level_prefix="ERROR" ;;
  esac

  for message in "$@"; do
    echo "$level_prefix: $message -> (from $caller_info)" >> "$output"
  done
)

function tmux::bootstrap::caller_formatter() {
  read -r -a array <<< "$@"
  for index in "${!array[@]}"; do
    case "${index}" in
      0) echo -n "line: ${array[$index]}, " ;;
      1) echo -n "function: ${array[$index]}, " ;;
      *) echo -n "file: ${array[*]:$index}"
        break ;;
    esac
  done
  echo ''
}
