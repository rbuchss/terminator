#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/version.sh"

function tmux::version() {
  command tmux -V | grep -E -o '([0-9.]+)'
}

function tmux::version::compare() {
  if (( $# != 2 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "usage: ${FUNCNAME[0]} comparison value"
    return 1
  fi

  case "$1" in
    less_than) tmux::version::compare::less_than "$2" ;;
    less_than_or_equal) tmux::version::compare::less_than_or_equal "$2" ;;
    equals) tmux::version::compare::equals "$2" ;;
    greater_than) tmux::version::compare::greater_than "$2" ;;
    greater_than_or_equal) tmux::version::compare::greater_than_or_equal "$2" ;;
    *)
      >&2 echo "ERROR: ${FUNCNAME[0]}: invalid comparison: '$1'"
      return 1
      ;;
  esac
}

function tmux::version::compare::less_than() {
  terminator::version::compare "$(tmux::version)" "$1"
  (( $? == 2 ))
}

function tmux::version::compare::less_than_or_equal() {
  terminator::version::compare "$(tmux::version)" "$1" \
    && return 0
  (( $? == 2 ))
}

function tmux::version::compare::equals() {
  terminator::version::compare "$(tmux::version)" "$1"
}

function tmux::version::compare::greater_than() {
  terminator::version::compare "$(tmux::version)" "$1"
  (( $? == 1 ))
}

function tmux::version::compare::greater_than_or_equal() {
  terminator::version::compare "$(tmux::version)" "$1" \
    && return 0
  (( $? == 1 ))
}
