#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utility.sh"

function terminator::postgresql::list_config() {
  psql -qAt -c 'show hba_file' | xargs grep -v -E '^[[:space:]]*#'
}

function terminator::postgresql::edit_config() {
  vi "$(psql -qAt  -c 'SHOW config_file')"
}

# from https://stackoverflow.com/questions/13573204/psql-could-not-connect-to-server-no-such-file-or-directory-mac-os-x
function terminator::postgresql::clear_pid() {
  local path file
  path="$(brew --prefix)/var"
  file="${path}/postgres/postmaster.pid"

  less "${path}/log/postgres.log"
  if terminator::utility::ask "move ${file}?"; then
    sudo mv "${file}" "${HOME}/"
  fi
}
