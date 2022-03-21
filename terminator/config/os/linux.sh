#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  # Check if display is available
  if [[ -n "${DISPLAY+x}" ]]; then
    # make caps lock actually useful (in linux)
    if command -v xmodmap > /dev/null 2>&1; then
      xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'
    fi
  fi

  # enable bash completion in interactive shells
  terminator::source \
    '/etc/bash_completion' \
    "${HOME}/git-prompt.sh" \
    "${HOME}/git-completion.bash"
fi
