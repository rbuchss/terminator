#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

terminator::__module__::load || return 0

function terminator::os::switch {
  local darwin_block=terminator::os::switch::darwin_default \
    linux_block=terminator::os::switch::linux_default \
    windows_block=terminator::os::switch::windows_default \
    unsupported_block=terminator::os::switch::unsupported_default \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        terminator::os::switch::usage
        return 0
        ;;
      -d | --darwin)
        shift
        darwin_block="$1"
        ;;
      -l | --linux)
        shift
        linux_block="$1"
        ;;
      -w | --windows)
        shift
        windows_block="$1"
        ;;
      -u | --unsupported)
        shift
        unsupported_block="$1"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        terminator::os::switch::usage >&2
        return 1
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  case "${OSTYPE}" in
    darwin*) "${darwin_block}" "${arguments[@]}" ;;
    linux*) "${linux_block}" "${arguments[@]}" ;;
    msys*) "${windows_block}" "${arguments[@]}" ;;
    *) "${unsupported_block}" "${arguments[@]}" ;;
  esac
}

function terminator::os::switch::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] <args>

  -d, --darwin       Function, command or script used to run if OS is darwin.
                     Default: terminator::os::switch::darwin_default

  -l, --linux        Function, command or script used to run if OS is linux.
                     Default: terminator::os::switch::linux_default

  -d, --windows      Function, command or script used to run if OS is windows.
                     Default: terminator::os::switch::windows_default

  -d, --unsupported  Function, command or script used to run if OS is unsupported.
                     Default: terminator::os::switch::unsupported_default

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::os::switch::darwin_default {
  terminator::log::warning "${FUNCNAME[0]}: noop -> args: $*"
}

function terminator::os::switch::linux_default {
  terminator::log::warning "${FUNCNAME[0]}: noop -> args: $*"
}

function terminator::os::switch::windows_default {
  terminator::log::warning "${FUNCNAME[0]}: noop -> args: $*"
}

function terminator::os::switch::unsupported_default {
  terminator::log::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::os::__export__ {
  export -f terminator::os::switch
  export -f terminator::os::switch::usage
  export -f terminator::os::switch::darwin_default
  export -f terminator::os::switch::linux_default
  export -f terminator::os::switch::windows_default
  export -f terminator::os::switch::unsupported_default
}

function terminator::os::__recall__ {
  export -fn terminator::os::switch
  export -fn terminator::os::switch::usage
  export -fn terminator::os::switch::darwin_default
  export -fn terminator::os::switch::linux_default
  export -fn terminator::os::switch::windows_default
  export -fn terminator::os::switch::unsupported_default
}

terminator::__module__::export
