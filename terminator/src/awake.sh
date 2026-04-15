#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/os.sh"

terminator::__module__::load || return 0

TERMINATOR_AWAKE_DEFAULT_HOURS=2
TERMINATOR_AWAKE_COMPLETION_HOURS=(0.5 1 2 4 6 8 12 24)

function terminator::awake::__enable__ {
  terminator::os::switch \
    --darwin terminator::awake::__enable__::os::darwin \
    --linux terminator::awake::__enable__::os::linux \
    --windows terminator::awake::__enable__::os::windows \
    --unsupported terminator::awake::__enable__::os::unsupported
}

function terminator::awake::__disable__ {
  unalias awake 2>/dev/null
  terminator::awake::completion::remove_alias 'awake'
}

function terminator::awake::__enable__::os::darwin {
  terminator::command::exists -v caffeinate || return

  alias awake='terminator::awake::invoke'
  terminator::awake::completion::add_alias 'awake'
}

function terminator::awake::__enable__::os::linux {
  terminator::command::exists -v systemd-inhibit || return

  alias awake='terminator::awake::invoke'
  terminator::awake::completion::add_alias 'awake'
}

function terminator::awake::__enable__::os::windows {
  terminator::awake::__enable__::os::unsupported
}

function terminator::awake::__enable__::os::unsupported {
  terminator::logger::error "OS '${OSTYPE}' not supported"
  return 1
}

# Keeps the display awake for a given number of hours.
# Usage: awake [OPTIONS] [HOURS]
#   HOURS defaults to TERMINATOR_AWAKE_DEFAULT_HOURS (2).
#   Additional flags are forwarded to the underlying OS command.
function terminator::awake::invoke {
  local \
    hours="${TERMINATOR_AWAKE_DEFAULT_HOURS}" \
    extra_args=()

  while (($# != 0)); do
    case "$1" in
      -h | --help)
        >&2 terminator::awake::invoke::usage
        return 0
        ;;
      -*)
        extra_args+=("$1")
        ;;
      *)
        hours="$1"
        ;;
    esac
    shift
  done

  if ! [[ "${hours}" =~ ^[0-9]+\.?[0-9]*$ ]] || [[ "${hours}" == 0 ]]; then
    terminator::logger::error "invalid hours: '${hours}', must be a positive number"
    >&2 terminator::awake::invoke::usage
    return 1
  fi

  # Uses bc instead of $(( )) because bash arithmetic is integer-only
  # and hours supports decimals (e.g. 0.5 for 30 minutes).
  local seconds
  seconds=$(printf '%.0f' "$(echo "${hours} * 3600" | bc)")

  echo "keeping display awake for ${hours} hour(s) (${seconds}s)"

  terminator::os::switch \
    --darwin terminator::awake::invoke::os::darwin \
    --linux terminator::awake::invoke::os::linux \
    --windows terminator::awake::invoke::os::windows \
    --unsupported terminator::awake::invoke::os::unsupported \
    -- "${seconds}" "${extra_args[@]}"
}

function terminator::awake::invoke::os::darwin {
  local seconds="$1"
  shift
  command caffeinate -d -t "${seconds}" "$@"
}

function terminator::awake::invoke::os::linux {
  local seconds="$1"
  shift
  command systemd-inhibit \
    --what=idle \
    --who='terminator::awake' \
    --reason='user requested display stay awake' \
    sleep "${seconds}" "$@"
}

function terminator::awake::invoke::os::windows {
  terminator::awake::invoke::os::unsupported "$@"
}

function terminator::awake::invoke::os::unsupported {
  terminator::logger::error "OS '${OSTYPE}' not supported"
  return 1
}

function terminator::awake::invoke::usage {
  cat <<USAGE_TEXT
Usage: awake [OPTIONS] [HOURS]

  Keeps the display awake for a given number of hours.
  Uses caffeinate on macOS, systemd-inhibit on Linux.

  HOURS    Number of hours to stay awake (default: ${TERMINATOR_AWAKE_DEFAULT_HOURS}).
           Supports decimals, e.g. 0.5 for 30 minutes.

  Additional flags are forwarded to the underlying OS command.

  -h, --help    Display this help message
USAGE_TEXT
}

function terminator::awake::completion {
  local word="${COMP_WORDS[COMP_CWORD]}"

  COMPREPLY=()

  while IFS='' read -r completion; do
    COMPREPLY+=("${completion}")
  done < <(compgen -W "${TERMINATOR_AWAKE_COMPLETION_HOURS[*]}" -- "${word}")
}

function terminator::awake::completion::add_alias {
  local name
  for name in "$@"; do
    complete -F terminator::awake::completion "${name}"
  done
}

function terminator::awake::completion::remove_alias {
  local name
  for name in "$@"; do
    complete -r "${name}" 2>/dev/null
  done
}

function terminator::awake::__export__ {
  export -f terminator::awake::invoke
  export -f terminator::awake::invoke::os::darwin
  export -f terminator::awake::invoke::os::linux
  export -f terminator::awake::invoke::os::windows
  export -f terminator::awake::invoke::os::unsupported
  export -f terminator::awake::invoke::usage
  export -f terminator::awake::completion
  export -f terminator::awake::completion::add_alias
  export -f terminator::awake::completion::remove_alias
}

# KCOV_EXCL_START
function terminator::awake::__recall__ {
  export -fn terminator::awake::invoke
  export -fn terminator::awake::invoke::os::darwin
  export -fn terminator::awake::invoke::os::linux
  export -fn terminator::awake::invoke::os::windows
  export -fn terminator::awake::invoke::os::unsupported
  export -fn terminator::awake::invoke::usage
  export -fn terminator::awake::completion
  export -fn terminator::awake::completion::add_alias
  export -fn terminator::awake::completion::remove_alias
}
# KCOV_EXCL_STOP

terminator::__module__::export
