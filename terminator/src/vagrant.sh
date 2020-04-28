#!/bin/bash

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
