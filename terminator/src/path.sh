#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::path::prepend() {
  for element in "$@"; do
    if terminator::path::excludes "${element}"; then
      PATH="${element}${PATH:+:${PATH}}"
    fi
  done

  export PATH
}

function terminator::path::append() {
  for element in "$@"; do
    if terminator::path::excludes "${element}"; then
      PATH="${PATH:+${PATH}:}${element}"
    fi
  done

  export PATH
}

function terminator::path::includes() {
  case ":${PATH}:" in
    *:$1:*) return 0 ;;
    *) return 1 ;;
  esac
}

function terminator::path::excludes() {
  ! terminator::path::includes "$@"
}

function terminator::path::clear() {
  # shellcheck disable=SC2123
  PATH=''
}

function terminator::cdpath::prepend() {
  for element in "$@"; do
    if terminator::cdpath::excludes "${element}"; then
      CDPATH="${element}${CDPATH:+:${CDPATH}}"
    fi
  done

  export CDPATH
}

function terminator::cdpath::append() {
  for element in "$@"; do
    if terminator::cdpath::excludes "${element}"; then
      CDPATH="${CDPATH:+${CDPATH}:}${element}"
    fi
  done

  export CDPATH
}

function terminator::cdpath::includes() {
  case ":${CDPATH}:" in
    *:$1:*) return 0 ;;
    *) return 1 ;;
  esac
}

function terminator::cdpath::excludes() {
  ! terminator::cdpath::includes "$@"
}

function terminator::cdpath::clear() {
  CDPATH=''
}

function terminator::manpath::prepend() {
  for element in "$@"; do
    if terminator::manpath::excludes "${element}"; then
      MANPATH="${element}${MANPATH:+:${MANPATH}}"
    fi
  done

  export MANPATH
}

function terminator::manpath::append() {
  for element in "$@"; do
    if terminator::manpath::excludes "${element}"; then
      MANPATH="${MANPATH:+${MANPATH}:}${element}"
    fi
  done

  export MANPATH
}

function terminator::manpath::includes() {
  case ":${MANPATH}:" in
    *:$1:*) return 0 ;;
    *) return 1 ;;
  esac
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

function terminator::path::__export__() {
  export -f terminator::path::prepend
  export -f terminator::path::append
  export -f terminator::path::includes
  export -f terminator::path::excludes
  export -f terminator::path::clear
  export -f terminator::cdpath::prepend
  export -f terminator::cdpath::append
  export -f terminator::cdpath::includes
  export -f terminator::cdpath::excludes
  export -f terminator::cdpath::clear
  export -f terminator::manpath::prepend
  export -f terminator::manpath::append
  export -f terminator::manpath::includes
  export -f terminator::manpath::excludes
  export -f terminator::manpath::clear
  export -f terminator::paths::clear
}

function terminator::path::__recall__() {
  export -fn terminator::path::prepend
  export -fn terminator::path::append
  export -fn terminator::path::includes
  export -fn terminator::path::excludes
  export -fn terminator::path::clear
  export -fn terminator::cdpath::prepend
  export -fn terminator::cdpath::append
  export -fn terminator::cdpath::includes
  export -fn terminator::cdpath::excludes
  export -fn terminator::cdpath::clear
  export -fn terminator::manpath::prepend
  export -fn terminator::manpath::append
  export -fn terminator::manpath::includes
  export -fn terminator::manpath::excludes
  export -fn terminator::manpath::clear
  export -fn terminator::paths::clear
}

terminator::__module__::export
