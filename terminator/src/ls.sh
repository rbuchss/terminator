#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::ls::__enable__ {
  terminator::command::exists -v ls || return

  alias ls='ls --color=auto'
  alias l='ls -CF'
  alias la='ls -a'
  alias ll='ls -lkh'
  alias lla='ll -a'
  alias lrt='ll -rt'
  alias lrta='lrt -a'
  alias lrtr='lrt -R'
  alias lrs='ll -rS'
  alias lrsa='lrs -a'
  alias lrsr='lrs -R'
  alias lr='ls -R'
  alias llr='ll -R'
  alias llra='llr -a'
}

function terminator::ls::__disable__ {
  unalias ls
  unalias l
  unalias la
  unalias ll
  unalias lla
  unalias lrt
  unalias lrta
  unalias lrtr
  unalias lrs
  unalias lrsa
  unalias lrsr
  unalias lr
  unalias llr
  unalias llra
}

function terminator::ls::__export__ {
  :
}

function terminator::ls::__recall__ {
  :
}

terminator::__module__::export
