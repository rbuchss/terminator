#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::less::__enable__ {
  terminator::command::exists -v less || return

  # make less and man pages more readable
  LESS_TERMCAP_mb="$(printf "\e[1;31m")"
  LESS_TERMCAP_md="$(printf "\e[1;31m")"
  LESS_TERMCAP_me="$(printf "\e[0m")"
  LESS_TERMCAP_se="$(printf "\e[0m")"
  LESS_TERMCAP_so="$(printf "\e[1;44;33m")"
  LESS_TERMCAP_ue="$(printf "\e[0m")"
  LESS_TERMCAP_us="$(printf "\e[1;32m")"

  export LESS_TERMCAP_mb
  export LESS_TERMCAP_md
  export LESS_TERMCAP_me
  export LESS_TERMCAP_se
  export LESS_TERMCAP_so
  export LESS_TERMCAP_ue
  export LESS_TERMCAP_us
}

function terminator::less::__disable__ {
  unset LESS_TERMCAP_mb
  unset LESS_TERMCAP_md
  unset LESS_TERMCAP_me
  unset LESS_TERMCAP_se
  unset LESS_TERMCAP_so
  unset LESS_TERMCAP_ue
  unset LESS_TERMCAP_us
}

function terminator::less::__export__ {
  :
}

function terminator::less::__recall__ {
  :
}

terminator::__module__::export
