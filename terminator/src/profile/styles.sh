#!/bin/bash

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/styles.sh"

function terminator::profile::styles::username() {
  echo '\u'
}

function terminator::profile::styles::user_color() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_USER_COLOR}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_USER_COLOR}"
    return 0
  fi

  terminator::styles::color::code '38;5;69m'
}

function terminator::profile::styles::user_separator() {
  echo '@'
}

function terminator::profile::styles::hostname() {
  echo '\h'
}

function terminator::profile::styles::host_color() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_HOST_COLOR}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_HOST_COLOR}"
    return 0
  fi

  terminator::styles::color::code '0;94m'
}

function terminator::profile::styles::host_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_HOST_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_HOST_SYMBOL}"
    return 0
  fi

  echo ''
}

function terminator::profile::styles::path() {
  echo '\w'
}

function terminator::profile::styles::path_color() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_PATH_COLOR}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_PATH_COLOR}"
    return 0
  fi

  terminator::styles::color::code '38;5;186m'
}

function terminator::profile::styles::command_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_COMMAND_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_COMMAND_SYMBOL}"
    return 0
  fi

  echo '$'
}

function terminator::profile::styles::error_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_ERROR_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_ERROR_SYMBOL}"
    return 0
  fi

  echo 'x'
}

function terminator::profile::styles::error_color() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_ERROR_COLOR}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_ERROR_COLOR}"
    return 0
  fi

  # export IRed="\[\033[0;91m\]"         # Red
  # color="$(color_code "38;5;9m")"
  terminator::styles::color::code '0;91m'
}

function terminator::profile::styles::warning_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_WARNING_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_WARNING_SYMBOL}"
    return 0
  fi

  echo '?'
}

function terminator::profile::styles::warning_color() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_WARNING_COLOR}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_WARNING_COLOR}"
    return 0
  fi

  # export IYellow="\[\033[0;93m\]"      # Yellow
  terminator::styles::color::code '0;93m'
}

function terminator::profile::styles::ok_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_OK_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_OK_SYMBOL}"
    return 0
  fi

  echo ''
}

function terminator::profile::styles::ok_color() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_OK_COLOR}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_OK_COLOR}"
    return 0
  fi

  # export IGreen="\[\033[0;92m\]"       # Green
  # color="$(color_code "38;5;10m")"
  terminator::styles::color::code '0;92m'
}

function terminator::profile::styles::branch_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_BRANCH_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_BRANCH_SYMBOL}"
    return 0
  fi

  # U+2B60 - 2640 menlo for powerline
  # U+E0A0 - 1617 monaco for powerline
  echo -e '\xe2\xad\xa0'
}

function terminator::profile::styles::detached_head_symbol() {
  if [[ -n "${TERMINATOR_PROFILE_STYLES_DETACHED_HEAD_SYMBOL}" ]]; then
    echo "${TERMINATOR_PROFILE_STYLES_DETACHED_HEAD_SYMBOL}"
    return 0
  fi

  # u+27a6
  echo ''
}
