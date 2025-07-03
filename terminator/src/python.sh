#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::python::__enable__ {
  terminator::command::any_exist -v pyenv python3 python || return

  alias py='terminator::python::invoke'
}

function terminator::python::__disable__ {
  unalias py
}

function terminator::python::invoke {
  local \
    major_version="${TERMINATOR_PYTHON_MAJOR_VERSION:-3}" \
    python_command \
    python_provider \
    python_providers=(
      uv
      pyenv
      homebrew
      system
    )

  for python_provider in "${python_providers[@]}"; do
    terminator::log::info "Try using python provider: ${python_provider}"

    if python_command="$("terminator::python::invoke::with_${python_provider}" "${major_version}")"; then
      terminator::log::info "Success ${python_provider} has python command: '${python_command}'"

      command "${python_command}" "$@"
      return
    fi
  done

  terminator::python::invoke::error "${major_version}"
  return 1
}

function terminator::python::invoke::with_uv {
  local \
    major_version="${1:?}" \
    full_path

  if ! command -v uv > /dev/null 2>&1; then
    terminator::log::debug 'Cannot find uv'
    return 1
  fi

  if ! full_path="$(uv python find --managed-python "${major_version}" 2>/dev/null)"; then
    terminator::log::warning "uv installed but no installed python versions match major version: '${major_version}'"
    return 1
  fi

  echo "${full_path}"
}

function terminator::python::invoke::with_pyenv {
  local \
    major_version="${1:?}" \
    full_version \
    full_path

  if ! command -v pyenv > /dev/null 2>&1; then
    terminator::log::debug 'Cannot find pyenv'
    return 1
  fi

  if ! full_version="$(pyenv latest "${major_version}" 2>/dev/null)"; then
    terminator::log::warning "pyenv installed but no installed python versions match major version: '${major_version}'"
    return 1
  fi

  short_version="${full_version%.*}"

  terminator::log::debug "Attempting to using pyenv python version: ${full_version} -> ${short_version}"

  full_path="$(pyenv root)/shims/python${short_version}"

  if ! [[ -x "${full_path}" ]]; then
    terminator::log::warning "pyenv installed but no shims match version: '${short_version}' at '${full_path}'"
    return 1
  fi

  terminator::log::debug "Using pyenv python version: ${full_version} -> ${short_version} at '${full_path}'"

  echo "${full_path}"
}

function terminator::python::invoke::with_homebrew {
  local \
    major_version="${1:?}" \
    prefix_path \
    full_path

  if ! command -v brew > /dev/null 2>&1; then
    terminator::log::debug 'Cannot find homebrew'
    return 1
  fi

  if ! prefix_path="$(brew --prefix "python@${major_version}" 2>/dev/null)"; then
    terminator::log::warning "homebrew installed but no installed python versions match major version: '${major_version}'"
    return 1
  fi

  full_path="${prefix_path}/bin/python${major_version}"

  if ! [[ -x "${full_path}" ]]; then
    terminator::log::warning "homebrew installed but no executable matches version: '${prefix_path}' at '${full_path}'"
    return 1
  fi

  terminator::log::debug "Using homebrew python version: ${prefix_path} at '${full_path}'"

  echo "${full_path}"
}

function terminator::python::invoke::with_system {
  local \
    major_version="${1:?}" \
    full_path

  if ! full_path="$(command -v "python${major_version}" 2>/dev/null)"; then
    terminator::log::warning "no system installed python versions match major version: '${major_version}'"
    return 1
  fi

  echo "${full_path}"
}

function terminator::python::invoke::error {
  local major_version="$1"
  terminator::log::error "Using python major version ${major_version} not supported"
  return 1
}

function terminator::python::__export__ {
  export -f terminator::python::invoke
  export -f terminator::python::invoke::error
  export -f terminator::python::invoke::with_uv
  export -f terminator::python::invoke::with_pyenv
  export -f terminator::python::invoke::with_homebrew
  export -f terminator::python::invoke::with_system
}

function terminator::python::__recall__ {
  export -fn terminator::python::invoke
  export -fn terminator::python::invoke::error
  export -fn terminator::python::invoke::with_uv
  export -fn terminator::python::invoke::with_pyenv
  export -fn terminator::python::invoke::with_homebrew
  export -fn terminator::python::invoke::with_system
}

terminator::__module__::export
