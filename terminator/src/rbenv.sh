#!/bin/bash

function terminator::rbenv::bootstrap() {
  if command -v rbenv > /dev/null 2>&1; then
    eval "$(rbenv init -)" > /dev/null
    # shellcheck source=/dev/null
    source "$(brew --prefix rbenv)/completions/rbenv.bash"
  fi
}
