#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*/*}/version.sh"

terminator::__module__::load || return 0

function terminator::tmux::version() {
  command tmux -V | grep -E -o '([0-9.]+)'
}

function terminator::tmux::version::compare() {
  if (( $# != 2 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "usage: ${FUNCNAME[0]} comparison value"
    return 1
  fi

  case "$1" in
    less_than) terminator::tmux::version::compare::less_than "$2" ;;
    less_than_or_equal) terminator::tmux::version::compare::less_than_or_equal "$2" ;;
    equals) terminator::tmux::version::compare::equals "$2" ;;
    greater_than) terminator::tmux::version::compare::greater_than "$2" ;;
    greater_than_or_equal) terminator::tmux::version::compare::greater_than_or_equal "$2" ;;
    *)
      >&2 echo "ERROR: ${FUNCNAME[0]}: invalid comparison: '$1'"
      return 1
      ;;
  esac
}

function terminator::tmux::version::compare::less_than() {
  terminator::version::compare "$(terminator::tmux::version)" "$1"
  (( $? == 2 ))
}

function terminator::tmux::version::compare::less_than_or_equal() {
  terminator::version::compare "$(terminator::tmux::version)" "$1" \
    && return 0
  (( $? == 2 ))
}

function terminator::tmux::version::compare::equals() {
  terminator::version::compare "$(terminator::tmux::version)" "$1"
}

function terminator::tmux::version::compare::greater_than() {
  terminator::version::compare "$(terminator::tmux::version)" "$1"
  (( $? == 1 ))
}

function terminator::tmux::version::compare::greater_than_or_equal() {
  terminator::version::compare "$(terminator::tmux::version)" "$1" \
    && return 0
  (( $? == 1 ))
}

function terminator::tmux::version::__export__() {
  export -f terminator::tmux::version
  export -f terminator::tmux::version::compare
  export -f terminator::tmux::version::compare::less_than
  export -f terminator::tmux::version::compare::less_than_or_equal
  export -f terminator::tmux::version::compare::equals
  export -f terminator::tmux::version::compare::greater_than
  export -f terminator::tmux::version::compare::greater_than_or_equal
}

function terminator::tmux::version::__recall__() {
  export -fn terminator::tmux::version
  export -fn terminator::tmux::version::compare
  export -fn terminator::tmux::version::compare::less_than
  export -fn terminator::tmux::version::compare::less_than_or_equal
  export -fn terminator::tmux::version::compare::equals
  export -fn terminator::tmux::version::compare::greater_than
  export -fn terminator::tmux::version::compare::greater_than_or_equal
}

terminator::__module__::export
