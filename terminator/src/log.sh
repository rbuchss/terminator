#!/bin/bash

function terminator::log::debug() {
  if [[ "${TERMINATOR_BOOTSTRAP_DEBUG}" == true ]]; then
    >&2 echo "$@"
  fi
}

function terminator::log::warning() {
  if [[ "${TERMINATOR_BOOTSTRAP_DEBUG}" == true ]]; then
    >&2 echo "$@"
  fi
}
