#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"

# export TERMINATOR_LOG_LEVEL='debug'
# export TERMINATOR_LOG_SILENCE=0

terminator::source "${HOME}/.terminator/src/bootstrap.sh"
terminator::bootstrap
