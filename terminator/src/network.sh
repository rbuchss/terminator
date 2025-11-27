#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::network::__enable__ {
  terminator::command::exists -v curl || return

  alias expand-url='terminator::network::expand_url'
  alias external-ip='terminator::network::external_ip'
}

function terminator::network::__disable__ {
  unalias expand-url
  unalias external-ip
}

function terminator::network::expand_url {
  curl -sIL "${1:?}" | grep ^Location:
}

function terminator::network::external_ip {
  # Uses dig to resolve the host external ip.
  #
  # This is an alternative for the curl method that is dns native:
  #
  #   curl ifconfig.me
  #
  dig +short myip.opendns.com @resolver1.opendns.com
}

function terminator::network::__export__ {
  export -f terminator::network::expand_url
  export -f terminator::network::external_ip
}

function terminator::network::__recall__ {
  export -fn terminator::network::expand_url
  export -fn terminator::network::external_ip
}

terminator::__module__::export
