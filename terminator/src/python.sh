#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::python::__enable__() {
  terminator::command::any_exist -v pyenv python3 python || return

  alias py='terminator::python::invoke'
}

function terminator::python::__disable__() {
  unalias py
}

function terminator::python::invoke() {
  local major_version="${TERMINATOR_PYTHON_MAJOR_VERSION:-3}"

  if command -v pyenv > /dev/null 2>&1; then
    local full_version

    full_version="$(pyenv latest "${major_version}")"
    short_version="${full_version%.*}"

    terminator::log::debug "Using pyenv python version: ${full_version} -> ${short_version}"

    command "python${short_version}" "$@"
    return
  fi

  case "${major_version}" in
    2)
      if command -v python2 > /dev/null 2>&1; then
        command python2 "$@"
      else
        terminator::python::invoke::error "${major_version}"
      fi
      ;;
    3)
      if command -v python3 > /dev/null 2>&1; then
        command python3 "$@"
      else
        terminator::python::invoke::error "${major_version}"
      fi
      ;;
    *)
      terminator::python::invoke::error "${major_version}"
      ;;
  esac
}

function terminator::python::invoke::error() {
  local major_version="$1"
  terminator::log::error "Using python major version ${major_version} not supported"
  return 1
}

function terminator::python::__export__() {
  export -f terminator::python::invoke
  export -f terminator::python::invoke::error
}

function terminator::python::__recall__() {
  export -fn terminator::python::invoke
  export -fn terminator::python::invoke::error
}

terminator::__module__::export
