#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::java::__enable__ {
  export JAVA_TOOL_OPTIONS='-Dlog4j2.formatMsgNoLookups=true'
}

function terminator::java::__disable__ {
  unset JAVA_TOOL_OPTIONS
}

function terminator::java::__export__ {
  :
}

function terminator::java::__recall__ {
  :
}

terminator::__module__::export
