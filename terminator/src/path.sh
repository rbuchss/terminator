#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

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
