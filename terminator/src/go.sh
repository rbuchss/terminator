#!/bin/bash

function terminator::go::bootstrap() {
  if command -v go > /dev/null 2>&1; then
    GOPATH="$(go env GOPATH)"
    export GOPATH
    export GOBIN="${GOPATH}/bin"
    terminator::path::prepend "${GOBIN}"
  else
    terminator::log::warning 'go is not installed'
  fi
}
