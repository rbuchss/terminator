#!/bin/bash

function terminator::git::url_parse() {
  sed -E 's#(git\@|https://)([^/:]+)(:|/)([^/]+)/(.+$)#'\\"$2"'#g' \
    <<< "$1"
}

function terminator::git::invoke() {
  if command -v hub > /dev/null 2>&1; then
    command hub "$@"
    return
  fi

  command git "$@"
}
