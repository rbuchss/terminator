#!/bin/bash

export TERMINATOR_LOG_LEVEL='info'
export TERMINATOR_LOG_SILENCE=0

# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"

terminator::source "${HOME}/.terminator/src/profile.sh"
terminator::profile::__initialize__
