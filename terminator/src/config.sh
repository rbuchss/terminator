#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/array.sh"
source "${BASH_SOURCE[0]%/*}/source.sh"

terminator::__module__::load || return 0

TERMINATOR_CONFIG_DIR="${HOME}/.config/terminator"
TERMINATOR_HOOKS_DIR="${TERMINATOR_CONFIG_DIR}/hooks"

function terminator::config::__enable__ {
  alias config-cd='terminator::config::cd'
  alias ccd='terminator::config::cd'

  terminator::config::cd::completion::add_alias \
    'config-cd' \
    'ccd'
}

function terminator::config::__disable__ {
  unalias config-cd
  unalias ccd

  terminator::config::cd::completion::remove_alias \
    'config-cd' \
    'ccd'
}

function terminator::config::path {
  local filepath="$1" \
    config_dir="${2:-${TERMINATOR_CONFIG_DIR}}"

  if [[ -z "${filepath}" ]]; then
    echo "${config_dir}"
  elif terminator::config::is_path_absolute "${filepath}"; then
    echo "${filepath}"
  else
    echo "${config_dir}/${filepath}"
  fi
}

function terminator::config::is_path_absolute {
  local filepath="$1"
  # shellcheck disable=SC2088
  [[ "${filepath:0:1}" == / || "${filepath:0:2}" == '~/' ]]
}

function terminator::config::cd {
  local config_dir="${1:-${TERMINATOR_CONFIG_DIR}}"

  cd "$(terminator::config::path "${config_dir}")" || return 1
}

function terminator::config::cd::completion {
  local \
    config_dir \
    word="${COMP_WORDS[COMP_CWORD]}"

  config_dir="$(terminator::config::path)"

  local suggestions=(
      "$(find "${config_dir}" \
        -type d \
        -mindepth 1 \
        | sed -E "s%${config_dir}/(.+)%\1%")"
      )

  COMPREPLY=()

  while IFS='' read -r completion; do
    # This filters out already matched completions
    if ! terminator::array::contains "${completion}" "${COMP_WORDS[@]}"; then
      COMPREPLY+=("${completion}")
    fi
  done < <(compgen -W "${suggestions[@]}" -- "${word}")
}

function terminator::config::cd::completion::add_alias {
  local name
  for name in "$@"; do
    complete -F terminator::config::cd::completion "${name}"
  done
}

function terminator::config::cd::completion::remove_alias {
  local name
  for name in "$@"; do
    complete -r "${name}"
  done
}

function terminator::config::load {
  local filepath
  for filepath in "$@"; do
    terminator::source "$(terminator::config::path "${filepath}")"
  done
}

function terminator::config::hooks::invoke {
  local hook_type="$1" \
    hooks_dir="$2" \
    hook_files=()

  if [[ -z "${hook_type}" ]]; then
    terminator::logger::error 'hook type not specified'
    return 1
  fi

  hook_dir="$(terminator::config::path "${hook_type}" "${hooks_dir:-${TERMINATOR_HOOKS_DIR}}")"

  while IFS='' read -r hook_file; do
    hook_files+=("${hook_file}")
  done < <(
    find "${hook_dir}" \
      -maxdepth 1 \
      \( -type f -o -type l \) \
      \( -name '*.sh' -o -name '*.bash' \) \
      | sort -n
  )

  if (( ${#hook_files[@]} == 0 )); then
    terminator::logger::debug "SKIPPING hook: '${hook_type}' - no files found in: '${hook_dir}'"
    return
  fi

  terminator::config::load "${hook_files[@]}"
}

function terminator::config::hooks::before {
  terminator::config::hooks::invoke \
    'before' \
    "${TERMINATOR_HOOKS_DIR}"
}

function terminator::config::hooks::after {
  terminator::config::hooks::invoke \
    'after' \
    "${TERMINATOR_HOOKS_DIR}"
}

function terminator::config::__export__ {
  export -f terminator::config::path
  export -f terminator::config::is_path_absolute
  export -f terminator::config::cd
  export -f terminator::config::cd::completion
  export -f terminator::config::cd::completion::add_alias
  export -f terminator::config::cd::completion::remove_alias
  export -f terminator::config::load
  export -f terminator::config::hooks::invoke
  export -f terminator::config::hooks::before
  export -f terminator::config::hooks::after
}

function terminator::config::__recall__ {
  export -fn terminator::config::path
  export -fn terminator::config::is_path_absolute
  export -fn terminator::config::cd
  export -fn terminator::config::cd::completion
  export -fn terminator::config::cd::completion::add_alias
  export -fn terminator::config::cd::completion::remove_alias
  export -fn terminator::config::load
  export -fn terminator::config::hooks::invoke
  export -fn terminator::config::hooks::before
  export -fn terminator::config::hooks::after
}

terminator::__module__::export
