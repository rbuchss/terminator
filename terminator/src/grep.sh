#!/bin/bash

function terminator::grep::invoke() {
  grep --color=auto \
    --exclude-dir='\.git' \
    --exclude-dir='\.svn' \
    "$@"
}
