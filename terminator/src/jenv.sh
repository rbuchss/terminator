#!/bin/bash

function terminator::jenv::bootstrap() {
  if command -v jenv > /dev/null 2>&1; then
    # export PATH="${HOME}/.jenv/bin:$PATH"
    eval "$(jenv init -)"
  else
    terminator::log::warning 'jenv is not installed'
  fi
}
