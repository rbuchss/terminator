#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::path::prepend() {
  local updated_path

  terminator::path::__prepend__ \
    --output updated_path \
    --path "${PATH-}" \
    "$@"

  export PATH="${updated_path}"
}

function terminator::path::append() {
  local updated_path

  terminator::path::__append__ \
    --output updated_path \
    --path "${PATH-}" \
    "$@"

  export PATH="${updated_path}"
}

function terminator::path::remove() {
  local updated_path

  terminator::path::__remove__ \
    --output updated_path \
    --path "${PATH}" \
    "$@"

  export PATH="${updated_path}"
}

function terminator::path::includes() {
  terminator::path::__includes__ "${PATH}" "$1"
}

function terminator::path::excludes() {
  ! terminator::path::includes "$@"
}

function terminator::path::clear() {
  # shellcheck disable=SC2123
  PATH=''
}

function terminator::cdpath::prepend() {
  local updated_cdpath

  terminator::path::__prepend__ \
    --output updated_cdpath \
    --path "${CDPATH-}" \
    "$@"

  export CDPATH="${updated_cdpath}"
}

function terminator::cdpath::append() {
  local updated_cdpath

  terminator::path::__append__ \
    --output updated_cdpath \
    --path "${CDPATH-}" \
    "$@"

  export CDPATH="${updated_cdpath}"
}

function terminator::cdpath::remove() {
  local updated_cdpath

  terminator::path::__remove__ \
    --output updated_cdpath \
    --path "${CDPATH}" \
    "$@"

  export CDPATH="${updated_cdpath}"
}

function terminator::cdpath::includes() {
  terminator::path::__includes__ "${CDPATH}" "$1"
}

function terminator::cdpath::excludes() {
  ! terminator::cdpath::includes "$@"
}

function terminator::cdpath::clear() {
  CDPATH=''
}

function terminator::manpath::prepend() {
  local updated_manpath

  terminator::path::__prepend__ \
    --output updated_manpath \
    --path "${MANPATH-}" \
    "$@"

  export MANPATH="${updated_manpath}"
}

function terminator::manpath::append() {
  local updated_manpath

  terminator::path::__append__ \
    --output updated_manpath \
    --path "${MANPATH-}" \
    "$@"

  export MANPATH="${updated_manpath}"
}

function terminator::manpath::remove() {
  local updated_manpath

  terminator::path::__remove__ \
    --output updated_manpath \
    --path "${MANPATH}" \
    "$@"

  export MANPATH="${updated_manpath}"
}

function terminator::manpath::includes() {
  terminator::path::__includes__ "${MANPATH}" "$1"
}

function terminator::manpath::excludes() {
  ! terminator::manpath::includes "$@"
}

function terminator::manpath::clear() {
  MANPATH=''
}

function terminator::paths::clear() {
  terminator::path::clear
  terminator::cdpath::clear
  terminator::manpath::clear
}

function terminator::path::__prepend__() {
  local _output_var \
    _output_var_used=0 \
    _path \
    _path_used=0 \
    _force=0 \
    _arguments=() \
    _ignored_count=0 \
    __prepend_tmp_path \
    _argument \
    _invalid_status=255

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::path::__prepend__::usage
        return "${_invalid_status}"
        ;;
      -f | --force)
        _force=1
        ;;
      -p | --path)
        if (( _path_used == 1 )); then
          >&2 echo "ERROR: ${FUNCNAME[0]} $1 specified more than once"
          >&2 terminator::path::__prepend__::usage
          return "${_invalid_status}"
        fi

        shift
        _path="$1"
        _path_used=1
        ;;
      -o | --output)
        if (( _output_var_used == 1 )); then
          >&2 echo "ERROR: ${FUNCNAME[0]} $1 specified more than once"
          >&2 terminator::path::__prepend__::usage
          return "${_invalid_status}"
        fi

        shift
        _output_var="$1"
        _output_var_used=1
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::path::__prepend__::usage
        return "${_invalid_status}"
        ;;
      *)
        _arguments+=("$1")
        ;;
    esac
    shift
  done

  for _argument in "${_arguments[@]}"; do
    if terminator::path::__excludes__ "${_path}" "${_argument}"; then
      _path="${_argument}${_path:+:${_path}}"
    elif (( _force == 1 )); then
      unset -v __prepend_tmp_path

      terminator::path::__remove__ \
        --output __prepend_tmp_path \
        --path "${_path}" \
        "${_argument}"

      _path="${_argument}${__prepend_tmp_path:+:${__prepend_tmp_path}}"
    else
      (( _ignored_count++ ))
    fi
  done

  if [[ -n "${_output_var}" ]]; then
    printf -v "${_output_var}" '%s' "${_path}"
  else
    echo "${_path}"
  fi

  return "${_ignored_count}"
}

function terminator::path::__prepend__::usage() {
  cat <<USAGE_TEXT
Prepends arguments to the specified path.
Usage: ${FUNCNAME[1]} [OPTIONS] <args>

  -f, --force        Force adds duplicate arguments.
                     Removes them from the specified path and adds them to the beginning.

  -p, --path         Path to prepend to.

  -o, --output       Output variable to write result to.
                     If none is specified writes the result to stdout.

  -h, --help         Display this help message

  Returns:
                     0 if all arguments are added successfully.
                     Or the number of ignored arguments if duplicate arguments are provided
                     and the force flag is not used.
                     Or the invalid status code 255 if the help or any other invalid flags are specified.
USAGE_TEXT
}

function terminator::path::__append__() {
  local _output_var \
    _output_var_used=0 \
    _path \
    _path_used=0 \
    _force=0 \
    _arguments=() \
    _ignored_count=0 \
    __append_tmp_path \
    _argument \
    _invalid_status=255

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::path::__append__::usage
        return "${_invalid_status}"
        ;;
      -f | --force)
        _force=1
        ;;
      -p | --path)
        if (( _path_used == 1 )); then
          >&2 echo "ERROR: ${FUNCNAME[0]} $1 specified more than once"
          >&2 terminator::path::__append__::usage
          return "${_invalid_status}"
        fi

        shift
        _path="$1"
        _path_used=1
        ;;
      -o | --output)
        if (( _output_var_used == 1 )); then
          >&2 echo "ERROR: ${FUNCNAME[0]} $1 specified more than once"
          >&2 terminator::path::__append__::usage
          return "${_invalid_status}"
        fi

        shift
        _output_var="$1"
        _output_var_used=1
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::path::__append__::usage
        return "${_invalid_status}"
        ;;
      *)
        _arguments+=("$1")
        ;;
    esac
    shift
  done

  for _argument in "${_arguments[@]}"; do
    if terminator::path::__excludes__ "${_path}" "${_argument}"; then
      _path="${_path:+${_path}:}${_argument}"
    elif (( _force == 1 )); then
      unset -v __append_tmp_path

      terminator::path::__remove__ \
        --output __append_tmp_path \
        --path "${_path}" \
        "${_argument}"

      _path="${__append_tmp_path:+${__append_tmp_path}:}${_argument}"
    else
      (( _ignored_count++ ))
    fi
  done

  if [[ -n "${_output_var}" ]]; then
    printf -v "${_output_var}" '%s' "${_path}"
  else
    echo "${_path}"
  fi

  return "${_ignored_count}"
}

function terminator::path::__append__::usage() {
  cat <<USAGE_TEXT
Appends arguments to the specified path.
Usage: ${FUNCNAME[1]} [OPTIONS] <args>

  -f, --force        Force adds duplicate arguments.
                     Removes them from the specified path and adds them to the end.

  -p, --path         Path to append to.

  -o, --output       Output variable to write result to.
                     If none is specified writes the result to stdout.

  -h, --help         Display this help message

  Returns:
                     0 if all arguments are added successfully.
                     Or the number of ignored arguments if duplicate arguments are provided
                     and the force flag is not used.
                     Or the invalid status code 255 if the help or any other invalid flags are specified.
USAGE_TEXT
}

function terminator::path::__remove__() {
  local _output_var \
    _output_var_used=0 \
    _path \
    _path_used=0 \
    _arguments=() \
    _argument \
    _invalid_status=255

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::path::__remove__::usage
        return "${_invalid_status}"
        ;;
      -p | --path)
        if (( _path_used == 1 )); then
          >&2 echo "ERROR: ${FUNCNAME[0]} $1 specified more than once"
          >&2 terminator::path::__remove__::usage
          return "${_invalid_status}"
        fi

        shift
        _path="$1"
        _path_used=1
        ;;
      -o | --output)
        if (( _output_var_used == 1 )); then
          >&2 echo "ERROR: ${FUNCNAME[0]} $1 specified more than once"
          >&2 terminator::path::__remove__::usage
          return "${_invalid_status}"
        fi

        shift
        _output_var="$1"
        _output_var_used=1
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 terminator::path::__remove__::usage
        return "${_invalid_status}"
        ;;
      *)
        _arguments+=("$1")
        ;;
    esac
    shift
  done

  _path=":${_path}:"

  for _argument in "${_arguments[@]}"; do
    if terminator::path::__includes__ "${_path}" "${_argument}"; then
      _path="${_path//:${_argument}:/:}"
    fi
  done

  _path="${_path#:}"
  _path="${_path%:}"

  if [[ -n "${_output_var}" ]]; then
    printf -v "${_output_var}" '%s' "${_path}"
  else
    echo "${_path}"
  fi
}

function terminator::path::__remove__::usage() {
  cat <<USAGE_TEXT
Removes arguments to the specified path.
Usage: ${FUNCNAME[1]} [OPTIONS] <args>

  -p, --path         Path to remove from.

  -o, --output       Output variable to write result to.
                     If none is specified writes the result to stdout.

  -h, --help         Display this help message

  Returns:
                     0 if all arguments are removed successfully.
                     Or the invalid status code 255 if the help or any other invalid flags are specified.
USAGE_TEXT
}

function terminator::path::__includes__() {
  [[ -z "$1" ]] && return 1

  case ":$1:" in
    *:$2:*) return 0 ;;
    *) return 1 ;;
  esac
}

function terminator::path::__excludes__() {
  ! terminator::path::__includes__ "$@"
}

function terminator::path::__export__() {
  export -f terminator::path::prepend
  export -f terminator::path::append
  export -f terminator::path::remove
  export -f terminator::path::includes
  export -f terminator::path::excludes
  export -f terminator::path::clear
  export -f terminator::cdpath::prepend
  export -f terminator::cdpath::append
  export -f terminator::cdpath::remove
  export -f terminator::cdpath::includes
  export -f terminator::cdpath::excludes
  export -f terminator::cdpath::clear
  export -f terminator::manpath::prepend
  export -f terminator::manpath::append
  export -f terminator::manpath::remove
  export -f terminator::manpath::includes
  export -f terminator::manpath::excludes
  export -f terminator::manpath::clear
  export -f terminator::paths::clear
}

function terminator::path::__recall__() {
  export -fn terminator::path::prepend
  export -fn terminator::path::append
  export -fn terminator::path::remove
  export -fn terminator::path::includes
  export -fn terminator::path::excludes
  export -fn terminator::path::clear
  export -fn terminator::cdpath::prepend
  export -fn terminator::cdpath::append
  export -fn terminator::cdpath::remove
  export -fn terminator::cdpath::includes
  export -fn terminator::cdpath::excludes
  export -fn terminator::cdpath::clear
  export -fn terminator::manpath::prepend
  export -fn terminator::manpath::append
  export -fn terminator::manpath::remove
  export -fn terminator::manpath::includes
  export -fn terminator::manpath::excludes
  export -fn terminator::manpath::clear
  export -fn terminator::paths::clear
}

terminator::__module__::export
