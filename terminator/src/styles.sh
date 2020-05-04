#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/color.sh"
source "${BASH_SOURCE[0]%/*}/unicode.sh"
source "${BASH_SOURCE[0]%/*}/user.sh"

function terminator::styles::newline() {
  local symbol

  case "${OSTYPE}" in
    msys*) symbol='\r\n' ;; # windows
    # solaris*) ;& # case fall-through not supported until bash-4
    # darwin*) ;&
    # linux*) ;&
    # bsd*) ;&
    *) symbol='\n' ;;
  esac

  case "$#" in
    1) read -r "$1" <<< "${symbol}" ;;
    *) echo "${symbol}" ;;
  esac
}

function terminator::styles::coalesce() {
  local cmd="$1"
  local environment_value="$2"
  local environment_code="$3"
  local default="$4"

  if [[ -n "${environment_value}" ]]; then
    case "$#" in
      5) read -r "$5" <<< "${environment_value}" ;;
      *) echo "${environment_value}" ;;
    esac
    return
  fi

  local code="${environment_code:-$default}"

  case "$#" in
    5) "${cmd}" "${code}" "$5" ;;
    *) "${cmd}" "${code}" ;;
  esac
}

function terminator::styles::color_coalesce() {
  terminator::styles::coalesce 'terminator::color::code' "$@"
}

function terminator::styles::unicode_coalesce() {
  terminator::styles::coalesce 'terminator::unicode::code' "$@"
}

function terminator::styles::char_coalesce() {
  local environment_value="$1"
  local default="$2"
  local symbol="${environment_value:-$default}"

  case "$#" in
    3) read -r "$3" <<< "${symbol}" ;;
    *) echo "${symbol}" ;;
  esac
}

function terminator::styles::username() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_USERNAME}" \
    '\u' \
    "$@"
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
    terminator::styles::root::user_separator "$@"
    return
  fi

  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_USER_SEPARATOR}" \
    '@' \
    "$@"
}

function terminator::styles::root::user_separator() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_ROOT_USER_SEPARATOR}" \
    '#' \
    "$@"
}

function terminator::styles::hostname() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_HOSTNAME}" \
    '\h' \
    "$@"
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
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_HOST_SYMBOL}" \
    "${TERMINATOR_STYLES_HOST_SYMBOL_CODE}" \
    0x262F \
    "$@"
}

function terminator::styles::path() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_PATH}" \
    '\w' \
    "$@"
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
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_JOBS}" \
    '\j' \
    "$@"
}

function terminator::styles::time() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_TIME}" \
    '\t' \
    "$@"
}

function terminator::styles::command_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL}" \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_CODE}" \
    0x03BB \
    "$@"
}

function terminator::styles::error_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_ERROR_SYMBOL}" \
    "${TERMINATOR_STYLES_ERROR_SYMBOL_CODE}" \
    0x2718 \
    "$@"
}

function terminator::styles::error_color() {
  # '38;5;9m'
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ERROR_COLOR}" \
    "${TERMINATOR_STYLES_ERROR_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function terminator::styles::warning_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_WARNING_SYMBOL}" \
    "${TERMINATOR_STYLES_WARNING_SYMBOL_CODE}" \
    0x3F \
    "$@"
}

function terminator::styles::warning_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_WARNING_COLOR}" \
    "${TERMINATOR_STYLES_WARNING_COLOR_CODE}" \
    '0;93m' \
    "$@"
}

function terminator::styles::ok_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_OK_SYMBOL}" \
    "${TERMINATOR_STYLES_OK_SYMBOL_CODE}" \
    0x2714 \
    "$@"
}

function terminator::styles::ok_color() {
  # '38;5;10m'
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_OK_COLOR}" \
    "${TERMINATOR_STYLES_OK_COLOR_CODE}" \
    '0;92m' \
    "$@"
}

function terminator::styles::branch_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_BRANCH_SYMBOL}" \
    "${TERMINATOR_STYLES_BRANCH_SYMBOL_CODE}" \
    0xE0A0 \
    "$@"
}

function terminator::styles::branch_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_BRANCH_COLOR}" \
    "${TERMINATOR_STYLES_BRANCH_COLOR_CODE}" \
    '38;5;69m' \
    "$@"
}

function terminator::styles::detached_head_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL}" \
    "${TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL_CODE}" \
    0x27A6 \
    "$@"
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
