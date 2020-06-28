#!/bin/bash

function terminator::dotnet::bootstrap() {
  if command -v dotnet > /dev/null 2>&1; then
    complete -f -F terminator::dotnet::complete dotnet
  fi
}

# bash parameter completion for the dotnet CLI
function terminator::dotnet::complete() {
  local word=${COMP_WORDS[COMP_CWORD]}

  local completions
  completions="$(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)"
  if [ $? -ne 0 ]; then
    completions=""
  fi

  COMPREPLY=( $(compgen -W "$completions" -- "$word") )
}
