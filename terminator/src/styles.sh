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

function terminator::styles::user_color() {
  if terminator::user::is_root; then
    terminator::styles::root::user_color
    return
  fi

  if [[ -n "${TERMINATOR_STYLES_USER_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_USER_COLOR}"
    return 0
  fi

  terminator::color::code '38;5;69m'
}

function terminator::styles::root::user_color() {
  if [[ -n "${TERMINATOR_STYLES_ROOT_USER_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_ROOT_USER_COLOR}"
    return 0
  fi

  terminator::color::code '0;91m'
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
    terminator::styles::root::host_color
    return
  fi

  if [[ -n "${TERMINATOR_STYLES_HOST_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_HOST_COLOR}"
    return 0
  fi

  terminator::color::code '0;94m'
}

function terminator::styles::root::host_color() {
  if [[ -n "${TERMINATOR_STYLES_ROOT_HOST_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_ROOT_HOST_COLOR}"
    return 0
  fi

  terminator::color::code '0;94m'
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
    terminator::styles::root::path_color
    return
  fi

  if [[ -n "${TERMINATOR_STYLES_PATH_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_PATH_COLOR}"
    return 0
  fi

  terminator::color::code '38;5;186m'
}

function terminator::styles::root::path_color() {
  if [[ -n "${TERMINATOR_STYLES_ROOT_PATH_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_ROOT_PATH_COLOR}"
    return 0
  fi

  terminator::color::code '0;94m'
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
  if [[ -n "${TERMINATOR_STYLES_ERROR_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_ERROR_COLOR}"
    return 0
  fi

  # color="$(color_code "38;5;9m")"
  terminator::color::code '0;91m'
}

function terminator::styles::warning_symbol() {
  if [[ -n "${TERMINATOR_STYLES_WARNING_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_WARNING_SYMBOL}"
    return 0
  fi

  echo '?'
}

function terminator::styles::warning_color() {
  if [[ -n "${TERMINATOR_STYLES_WARNING_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_WARNING_COLOR}"
    return 0
  fi

  terminator::color::code '0;93m'
}

function terminator::styles::ok_symbol() {
  if [[ -n "${TERMINATOR_STYLES_OK_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_OK_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0x2714
}

function terminator::styles::ok_color() {
  if [[ -n "${TERMINATOR_STYLES_OK_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_OK_COLOR}"
    return 0
  fi

  # color="$(color_code "38;5;10m")"
  terminator::color::code '0;92m'
}

function terminator::styles::branch_symbol() {
  if [[ -n "${TERMINATOR_STYLES_BRANCH_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_BRANCH_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0xE0A0
}

function terminator::styles::branch_color() {
  if [[ -n "${TERMINATOR_STYLES_BRANCH_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_BRANCH_COLOR}"
    return 0
  fi

  terminator::color::code '38;5;69m'
}

function terminator::styles::detached_head_symbol() {
  if [[ -n "${TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL}" ]]; then
    echo "${TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL}"
    return 0
  fi

  terminator::unicode::code 0x27A6
}

function terminator::styles::upstream_same_color() {
  if [[ -n "${TERMINATOR_STYLES_UPSTREAM_SAME_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_UPSTREAM_SAME_COLOR}"
    return 0
  fi

  terminator::color::code '38;5;69m'
}

function terminator::styles::upstream_ahead_color() {
  if [[ -n "${TERMINATOR_STYLES_UPSTREAM_AHEAD_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_UPSTREAM_AHEAD_COLOR}"
    return 0
  fi

  terminator::color::code '0;92m'
}

function terminator::styles::upstream_behind_color() {
  if [[ -n "${TERMINATOR_STYLES_UPSTREAM_BEHIND_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_UPSTREAM_BEHIND_COLOR}"
    return 0
  fi

  terminator::color::code '0;91m'
}

function terminator::styles::upstream_gone_color() {
  if [[ -n "${TERMINATOR_STYLES_UPSTREAM_GONE_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_UPSTREAM_GONE_COLOR}"
    return 0
  fi

  terminator::color::code '0;91m'
}

function terminator::styles::index_color() {
  if [[ -n "${TERMINATOR_STYLES_INDEX_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_INDEX_COLOR}"
    return 0
  fi

  terminator::color::code '0;92m'
}

function terminator::styles::files_color() {
  if [[ -n "${TERMINATOR_STYLES_FILES_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_FILES_COLOR}"
    return 0
  fi

  terminator::color::code '0;91m'
}

function terminator::styles::divider_color() {
  if [[ -n "${TERMINATOR_STYLES_DIVIDER_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_DIVIDER_COLOR}"
    return 0
  fi

  terminator::color::code '0;93m'
}

function terminator::styles::enclosure_color() {
  if [[ -n "${TERMINATOR_STYLES_ENCLOSURE_COLOR}" ]]; then
    echo "${TERMINATOR_STYLES_ENCLOSURE_COLOR}"
    return 0
  fi

  terminator::color::code '0;90m'
}
