#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/array.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

terminator::__module__::load || return 0

function terminator::source() {
  for element in "$@"; do
    if [[ -s "${element}" ]]; then
      terminator::log::info "'${element}'"
      # shellcheck source=/dev/null
      source "${element}"
    else
      terminator::log::warning "'${element}' NOT found!"
    fi
  done
}

function terminator::source::__enable__() {
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
    terminator::__module__::unload_all
  else
    terminator::__module__::unload "${refresh_modules[@]}"
  fi

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
    suggestions=("${TERMINATOR_MODULES_LOADED[@]}")

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

function terminator::source::__export__() {
  export -f terminator::source
  export -f terminator::source::bash_profile
  export -f terminator::source::bash_profile::usage
  export -f terminator::source::bash_profile::completion
  export -f terminator::source::bash_profile::completion::add_alias
}

function terminator::source::__recall__() {
  export -fn terminator::source
  export -fn terminator::source::bash_profile
  export -fn terminator::source::bash_profile::usage
  export -fn terminator::source::bash_profile::completion
  export -fn terminator::source::bash_profile::completion::add_alias
}

terminator::__module__::export
