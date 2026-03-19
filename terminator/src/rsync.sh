#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

TERMINATOR_RSYNC_EXCLUDE_DIRS=()

function terminator::rsync::__enable__ {
  terminator::command::exists -v rsync || return

  alias rsync='terminator::rsync::invoke'
}

function terminator::rsync::__disable__ {
  unalias rsync 2>/dev/null
}

# Convenience wrapper around rsync with standard flags and exclude dirs.
# Uses plain SSH transport. For cloud provider transports, use workstation-rsync.
function terminator::rsync::invoke {
  local \
    __rsync_excludes__=() \
    __rsync_exclude_dir__ \
    __rsync_arguments__=()

  for __rsync_exclude_dir__ in "${TERMINATOR_RSYNC_EXCLUDE_DIRS[@]}"; do
    __rsync_excludes__+=("--exclude=${__rsync_exclude_dir__}")
  done

  __rsync_arguments__+=(
    -avz
    --progress
    "${__rsync_excludes__[@]}"
    -e ssh
    "$@"
  )

  echo "running: rsync ${__rsync_arguments__[*]}"

  command rsync "${__rsync_arguments__[@]}"
}

# Registers directories to exclude from rsync operations.
# Usage: exclude --dir NAME [--dir NAME ...]
function terminator::rsync::exclude {
  local -a dirs=()

  while (($# != 0)); do
    case "$1" in
      --dir)
        shift
        dirs+=("$1")
        ;;
      *)
        terminator::logger::warning "unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  if ((${#dirs[@]} == 0)); then
    terminator::logger::warning '--dir is required'
    return 1
  fi

  TERMINATOR_RSYNC_EXCLUDE_DIRS+=("${dirs[@]}")
}

function terminator::rsync::__export__ {
  export TERMINATOR_RSYNC_EXCLUDE_DIRS

  export -f terminator::rsync::invoke
  export -f terminator::rsync::exclude
}

# KCOV_EXCL_START
function terminator::rsync::__recall__ {
  unset TERMINATOR_RSYNC_EXCLUDE_DIRS

  export -fn terminator::rsync::invoke
  export -fn terminator::rsync::exclude
}
# KCOV_EXCL_STOP

terminator::__module__::export
