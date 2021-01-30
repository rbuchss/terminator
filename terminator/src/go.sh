#!/bin/bash

function terminator::go::bootstrap() {
  export GOPATH="$(go env GOPATH)"
  terminator::path::prepend "${GOPATH}/bin"
}
