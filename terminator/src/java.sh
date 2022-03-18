#!/bin/bash

function terminator::java::bootstrap() {
  export JAVA_TOOL_OPTIONS='-Dlog4j2.formatMsgNoLookups=true'
}
