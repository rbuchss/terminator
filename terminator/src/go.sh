#!/bin/bash

function terminator::go::bootstrap() {
  export GOPATH="$(go env GOPATH)"
  export GOBIN="${GOPATH}/bin"
  terminator::path::prepend "${GOBIN}"
}
