#!/bin/bash

# Reduce log noise in Claude Code shells to save tokens
if [[ -n "${CLAUDE_CODE_ENTRYPOINT}" ]]; then
  export TERMINATOR_LOG_LEVEL='error'
fi
