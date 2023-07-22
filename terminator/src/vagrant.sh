#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::vagrant::__initialize__() {
  if ! command -v vagrant > /dev/null 2>&1; then
    terminator::log::warning 'vagrant is not installed'
    return
  fi

  alias vagrant_scp='terminator::vagrant::scp'
}

function terminator::vagrant::scp() {
  scp -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -o IdentitiesOnly=yes \
    -o LogLevel=ERROR \
    -i "${HOME}/.vagrant.d/insecure_private_key" \
    -P 2202 \
    "$1" \
    vagrant@127.0.0.1:
}
