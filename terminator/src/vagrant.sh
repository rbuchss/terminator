#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::vagrant::bootstrap() {
  if command -v vagrant > /dev/null 2>&1; then
    alias vagrant_scp='terminator::vagrant::scp'
  else
    terminator::log::warning 'vagrant is not installed'
  fi
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
