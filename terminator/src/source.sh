#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/array.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

terminator::__pragma__::once || return 0

function terminator::source() {
  for element in "$@"; do
    if [[ -s "${element}" ]]; then
      terminator::log::debug "'${element}'"
      # shellcheck source=/dev/null
      source "${element}"
    else
      terminator::log::warning "'${element}' NOT found!"
    fi
  done
}

function terminator::source::bootstrap() {
  alias source_bash_profile='terminator::source::bash_profile'
  alias sbp='terminator::source::bash_profile'

  terminator::source::bash_profile::completion::add_alias \
    'source_bash_profile' \
    'sbp'
}

function terminator::source::bash_profile() {
  local refresh_all_modules=0 \
    refresh_modules=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        terminator::source::bash_profile::usage
        return 0
        ;;
      -f | --force)
        refresh_all_modules=1
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        terminator::source::bash_profile::usage >&2
        return 1
        ;;
      *)
        refresh_modules+=("$1")
        ;;
    esac
    shift
  done

  if (( refresh_all_modules == 1 )); then
    terminator::__pragma__::clear
  fi

  terminator::__pragma__::remove "${refresh_modules[@]}"

  terminator::source "${HOME}/.bash_profile"
}

function terminator::source::bash_profile::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] <cached modules to refresh>

  -f, --force        Forces all modules to refresh even if cached.

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::source::bash_profile::completion() {
  local word="${COMP_WORDS[COMP_CWORD]}" \
    suggestions=("${TERMINATOR_PRAGMA_LOADED_FILES[@]}")

  COMPREPLY=()

  while IFS='' read -r completion; do
    # This filters out already matched completions
    if ! terminator::array::contains "${completion}" "${COMP_WORDS[@]}"; then
      COMPREPLY+=("${completion}")
    fi
  done < <(compgen -W "${suggestions[*]}" -- "${word}")
}

function terminator::source::bash_profile::completion::add_alias() {
  for name in "$@"; do
    complete -F terminator::source::bash_profile::completion \
      'source_bash_profile' \
      "${name}"
  done
}
