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
    1) IFS='' read -r "$1" <<< "${symbol}" ;;
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
      5) IFS='' read -r "$5" <<< "${environment_value}" ;;
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
    3) IFS='' read -r "$3" <<< "${symbol}" ;;
    *) echo "${symbol}" ;;
  esac
}

function terminator::styles::command_coalesce() {
  local commands=() \
    invalid_commands=() \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        terminator::styles::command_coalesce::usage
        return 0
        ;;
      -c | --command)
        shift
        commands+=("$1")
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        terminator::styles::command_coalesce::usage >&2
        return 1
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  until (( ${#commands[@]} == 0 )) \
    || command -v "${commands[0]}" > /dev/null 2>&1; do
    invalid_commands+=("${commands[0]}")
    commands=("${commands[@]:1}")
  done

  if (( ${#commands[@]} == 0 )); then
      >&2 printf 'ERROR: %s no valid commands specified. Invalid commands: [%s]\n' \
        "${FUNCNAME[0]}" \
        "${invalid_commands[*]}"
      terminator::styles::command_coalesce::usage >&2
      return 1
  fi

  "${commands[0]}" "${arguments[@]}"
}

function terminator::styles::command_coalesce::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] <args>

  -c, --command      Function, command or script used to run if defined.
                     Uses first one that exists

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::styles::user_prefix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_USER_PREFIX}" \
    '' \
    "$@"
}

function terminator::styles::user_prefix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_USER_PREFIX_COLOR}" \
    "${TERMINATOR_STYLES_USER_PREFIX_COLOR_CODE}" \
    '38;5;69m' \
    "$@"
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

function terminator::styles::user_suffix_color() {
  if terminator::user::is_root; then
    terminator::styles::root::user_suffix_color "$@"
    return
  fi

  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_USER_SUFFIX_COLOR}" \
    "${TERMINATOR_STYLES_USER_SUFFIX_COLOR_CODE}" \
    '38;5;69m' \
    "$@"
}

function terminator::styles::root::user_suffix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ROOT_USER_SUFFIX_COLOR}" \
    "${TERMINATOR_STYLES_ROOT_USER_SUFFIX_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function terminator::styles::user_suffix() {
  if terminator::user::is_root; then
    terminator::styles::root::user_suffix "$@"
    return
  fi

  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_USER_SUFFIX}" \
    '@' \
    "$@"
}

function terminator::styles::root::user_suffix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_ROOT_USER_SUFFIX}" \
    '#' \
    "$@"
}

function terminator::styles::host_prefix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_HOST_PREFIX}" \
    '' \
    "$@"
}

function terminator::styles::host_prefix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_HOST_PREFIX_COLOR}" \
    "${TERMINATOR_STYLES_HOST_PREFIX_COLOR_CODE}" \
    '0m' \
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

function terminator::styles::host_suffix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_HOST_SUFFIX}" \
    '' \
    "$@"
}

function terminator::styles::host_suffix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_HOST_SUFFIX_COLOR}" \
    "${TERMINATOR_STYLES_HOST_SUFFIX_COLOR_CODE}" \
    '0m' \
    "$@"
}

function terminator::styles::directory_prefix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_DIRECTORY_PREFIX}" \
    ' ' \
    "$@"
}

function terminator::styles::directory_prefix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_DIRECTORY_PREFIX_COLOR}" \
    "${TERMINATOR_STYLES_DIRECTORY_PREFIX_COLOR_CODE}" \
    '0m' \
    "$@"
}

function terminator::styles::directory() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_DIRECTORY}" \
    '\w' \
    "$@"
}

function terminator::styles::directory_color() {
  if terminator::user::is_root; then
    terminator::styles::root::directory_color "$@"
    return
  fi

  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_DIRECTORY_COLOR}" \
    "${TERMINATOR_STYLES_DIRECTORY_COLOR_CODE}" \
    '38;5;186m' \
    "$@"
}

function terminator::styles::root::directory_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ROOT_DIRECTORY_COLOR}" \
    "${TERMINATOR_STYLES_ROOT_DIRECTORY_COLOR_CODE}" \
    '0;94m' \
    "$@"
}

function terminator::styles::directory_suffix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_DIRECTORY_SUFFIX}" \
    ' ' \
    "$@"
}

function terminator::styles::directory_suffix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_DIRECTORY_SUFFIX_COLOR}" \
    "${TERMINATOR_STYLES_DIRECTORY_SUFFIX_COLOR_CODE}" \
    '0m' \
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

function terminator::styles::command_symbol_prefix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX}" \
    '' \
    "$@"
}

function terminator::styles::command_symbol_prefix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX_COLOR}" \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX_COLOR_CODE}" \
    '0m' \
    "$@"
}

function terminator::styles::command_symbol() {
  terminator::styles::unicode_coalesce \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL}" \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_CODE}" \
    0x03BB \
    "$@"
}

function terminator::styles::command_symbol_suffix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX}" \
    ' ' \
    "$@"
}

function terminator::styles::command_symbol_suffix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX_COLOR}" \
    "${TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX_COLOR_CODE}" \
    '0m' \
    "$@"
}

function terminator::styles::right_prompt_prefix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX}" \
    '' \
    "$@"
}

function terminator::styles::right_prompt_prefix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX_COLOR}" \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX_COLOR_CODE}" \
    '0m' \
    "$@"
}

function terminator::styles::right_prompt_content() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT}" \
    '' \
    "$@"
}

function terminator::styles::right_prompt_content_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT_COLOR}" \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT_COLOR_CODE}" \
    '0m' \
    "$@"
}

function terminator::styles::right_prompt_suffix() {
  terminator::styles::char_coalesce \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX}" \
    '' \
    "$@"
}

function terminator::styles::right_prompt_suffix_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX_COLOR}" \
    "${TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX_COLOR_CODE}" \
    '0m' \
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

function terminator::styles::stash_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_STASH_COLOR}" \
    "${TERMINATOR_STYLES_STASH_COLOR_CODE}" \
    '38;5;214m' \
    "$@"
}

function terminator::styles::enclosure_color() {
  terminator::styles::color_coalesce \
    "${TERMINATOR_STYLES_ENCLOSURE_COLOR}" \
    "${TERMINATOR_STYLES_ENCLOSURE_COLOR_CODE}" \
    '0;90m' \
    "$@"
}
