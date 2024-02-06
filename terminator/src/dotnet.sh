#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::dotnet::__enable__ {
  terminator::command::exists -v dotnet || return

  complete -f -F terminator::dotnet::complete dotnet
}

function terminator::dotnet::__disable__ {
  complete -r dotnet
}

# bash parameter completion for the dotnet CLI
function terminator::dotnet::complete {
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

function terminator::dotnet::__export__ {
  export -f terminator::dotnet::complete
}

function terminator::dotnet::__recall__ {
  export -fn terminator::dotnet::complete
}

terminator::__module__::export
