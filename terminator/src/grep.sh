#!/bin/bash

function terminator::grep::invoke() {
  command grep --color=auto \
    --exclude-dir='\.git' \
    --exclude-dir='\.svn' \
    "$@"
}
