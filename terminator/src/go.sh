#!/bin/bash

function terminator::go::bootstrap() {
  GOPATH="$(go env GOPATH)"
  export GOPATH
  export GOBIN="${GOPATH}/bin"
  terminator::path::prepend "${GOBIN}"
}
