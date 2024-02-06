#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/source.sh"

terminator::__module__::load || return 0

TERMINATOR_CONFIG_DIR="${HOME}/.config/terminator"
TERMINATOR_HOOKS_DIR="${TERMINATOR_CONFIG_DIR}/hooks"

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
    terminator::log::error 'hook type not specified'
    return 1
  fi

  hook_dir="$(terminator::config::path "${hook_type}" "${hooks_dir:-${TERMINATOR_HOOKS_DIR}}")"

  while IFS='' read -r hook_file; do
    hook_files+=("${hook_file}")
  done < <(
    find "${hook_dir}" \
      -depth 1 \
      -type f \
      -or \
      -type l \
      -name '*.sh' \
      -or \
      -name '*.bash' \
      | sort -n
  )

  if (( ${#hook_files[@]} == 0 )); then
    terminator::log::debug "SKIPPING hook: '${hook_type}' - no files found in: '${hook_dir}'"
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
  export -f terminator::config::load
  export -f terminator::config::hooks::invoke
  export -f terminator::config::hooks::before
  export -f terminator::config::hooks::after
}

function terminator::config::__recall__ {
  export -fn terminator::config::path
  export -fn terminator::config::is_path_absolute
  export -fn terminator::config::load
  export -fn terminator::config::hooks::invoke
  export -fn terminator::config::hooks::before
  export -fn terminator::config::hooks::after
}

terminator::__module__::export
