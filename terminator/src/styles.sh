#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/color.sh"
source "${BASH_SOURCE[0]%/*}/unicode.sh"
source "${BASH_SOURCE[0]%/*}/user.sh"

function terminator::styles::newline() {
  # shellcheck disable=SC2028
  case "${OSTYPE}" in
    msys*) echo '\r\n' ;; # windows
    # solaris*) ;& # case fall-through not supported until bash-4
    # darwin*) ;&
    # linux*) ;&
    # bsd*) ;&
    *) echo '\n' ;;
  esac
}

function terminator::styles::username() {
  echo '\u'
}

function terminator::styles::color_coalesce() {
  local environment_value="$1"
  local environment_code="$2"
  local default="$3"

  if [[ -n "${environment_value}" ]]; then
    case "$#" in
      4) read -r "$4" <<< "${environment_value}" ;;
      *) echo "${environment_value}" ;;
    esac
    return
  fi

  local code="${environment_code:-$default}"

  case "$#" in
    4) terminator::color::code "${code}" "$4" ;;
    *) terminator::color::code "${code}" ;;
  esac
}

function terminator::styles::user_color() {
  if terminator::user::is_root; then
    terminator::styles::root::user_color "$@"
    return
  fi

  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_USER_COLOR}" \
    "${TERMINATOR_STYLES_USER_COLOR_CODE}" \
    '38;5;69m' \
    "$@"
}

function terminator::styles::root::user_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ROOT_USER_COLOR}" \
    "${TERMINATOR_STYLES_ROOT_USER_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function terminator::styles::user_separator() {
  if terminator::user::is_root; then
    echo '#'
    return
  fi

  echo '@'
}

function terminator::styles::hostname() {
  echo '\h'
}

function terminator::styles::host_color() {
  if terminator::user::is_root; then
    terminator::styles::root::host_color "$@"
    return
  fi

  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_HOST_COLOR}" \
    "${TERMINATOR_STYLES_HOST_COLOR_CODE}" \
    '0;94m' \
    "$@"
}

function terminator::styles::root::host_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ROOT_HOST_COLOR}" \
    "${TERMINATOR_STYLES_ROOT_HOST_COLOR_CODE}" \
    '0;94m' \
    "$@"
}

function terminator::styles::host_symbol() {
  if [[ -n "${TERMINATOR_STYLES_HOST_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_HOST_SYMBOL}"
    return 0
  fi

  echo ''
}

function terminator::styles::path() {
  echo '\w'
}

function terminator::styles::path_color() {
  if terminator::user::is_root; then
    terminator::styles::root::path_color "$@"
    return
  fi

  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_PATH_COLOR}" \
    "${TERMINATOR_STYLES_PATH_COLOR_CODE}" \
    '38;5;186m' \
    "$@"
}

function terminator::styles::root::path_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ROOT_PATH_COLOR}" \
    "${TERMINATOR_STYLES_ROOT_PATH_COLOR_CODE}" \
    '0;94m' \
    "$@"
}

function terminator::styles::jobs() {
  echo '\j'
}

function terminator::styles::time() {
  # shellcheck disable=SC2028
  echo '\t'
}

function terminator::styles::command_symbol() {
  if [[ -n "${TERMINATOR_STYLES_COMMAND_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_COMMAND_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0x03BB
}

function terminator::styles::error_symbol() {
  if [[ -n "${TERMINATOR_STYLES_ERROR_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_ERROR_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0x2718
}

function terminator::styles::error_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ERROR_COLOR}" \
    "${TERMINATOR_STYLES_ERROR_COLOR_CODE}" \
    '0;91m' \
    "$@"
  # color="$(color_code "38;5;9m")"
}

function terminator::styles::warning_symbol() {
  if [[ -n "${TERMINATOR_STYLES_WARNING_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_WARNING_SYMBOL}"
    return 0
  fi

  echo '?'
}

function terminator::styles::warning_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_WARNING_COLOR}" \
    "${TERMINATOR_STYLES_WARNING_COLOR_CODE}" \
    '0;93m' \
    "$@"
}

function terminator::styles::ok_symbol() {
  if [[ -n "${TERMINATOR_STYLES_OK_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_OK_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0x2714
}

function terminator::styles::ok_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_OK_COLOR}" \
    "${TERMINATOR_STYLES_OK_COLOR_CODE}" \
    '0;92m' \
    "$@"
  # color="$(color_code "38;5;10m")"
}

function terminator::styles::branch_symbol() {
  if [[ -n "${TERMINATOR_STYLES_BRANCH_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_BRANCH_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0xE0A0
}

function terminator::styles::branch_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_BRANCH_COLOR}" \
    "${TERMINATOR_STYLES_BRANCH_COLOR_CODE}" \
    '38;5;69m' \
    "$@"
}

function terminator::styles::detached_head_symbol() {
  if [[ -n "${TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0x27A6
}

function terminator::styles::upstream_same_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_UPSTREAM_SAME_COLOR}" \
    "${TERMINATOR_STYLES_UPSTREAM_SAME_COLOR_CODE}" \
    '38;5;69m' \
    "$@"
}

function terminator::styles::upstream_ahead_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_UPSTREAM_AHEAD_COLOR}" \
    "${TERMINATOR_STYLES_UPSTREAM_AHEAD_COLOR_CODE}" \
    '0;92m' \
    "$@"
}

function terminator::styles::upstream_behind_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_UPSTREAM_BEHIND_COLOR}" \
    "${TERMINATOR_STYLES_UPSTREAM_BEHIND_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function terminator::styles::upstream_gone_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_UPSTREAM_GONE_COLOR}" \
    "${TERMINATOR_STYLES_UPSTREAM_GONE_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function terminator::styles::index_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_INDEX_COLOR}" \
    "${TERMINATOR_STYLES_INDEX_COLOR_CODE}" \
    '0;92m' \
    "$@"
}

function terminator::styles::files_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_FILES_COLOR}" \
    "${TERMINATOR_STYLES_FILES_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function terminator::styles::divider_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_DIVIDER_COLOR}" \
    "${TERMINATOR_STYLES_DIVIDER_COLOR_CODE}" \
    '0;93m' \
    "$@"
}

function terminator::styles::enclosure_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ENCLOSURE_COLOR}" \
    "${TERMINATOR_STYLES_ENCLOSURE_COLOR_CODE}" \
    '0;90m' \
    "$@"
}
