#!/bin/bash

function terminator::homeshick::bootstrap() {
  local hsr="${HOME}/.homesick/repos"
  local homeshick_path="${hsr}/homeshick"

  if [[ -d "${homeshick_path}" ]]; then
    terminator::source \
      "${homeshick_path}/homeshick.sh" \
      "${homeshick_path}/completions/homeshick-completion.bash"
  else
    terminator::log::warning 'homeshick is not installed'
  fi
}
