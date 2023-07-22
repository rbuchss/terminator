#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::java::__initialize__() {
  export JAVA_TOOL_OPTIONS='-Dlog4j2.formatMsgNoLookups=true'
}
