#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::dotnet::bootstrap() {
  if command -v dotnet > /dev/null 2>&1; then
    complete -f -F terminator::dotnet::complete dotnet
  else
    terminator::log::warning 'dotnet is not installed'
  fi
}

# bash parameter completion for the dotnet CLI
function terminator::dotnet::complete() {
  COMPREPLY=()
  local word completions

  word="${COMP_WORDS[COMP_CWORD]}"

  if ! completions="$(dotnet complete \
    --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)"; then
      completions=""
  fi

  while IFS='' read -r completion; do
    COMPREPLY+=("${completion}")
  done < <(compgen -W "${completions}" -- "${word}")
}
