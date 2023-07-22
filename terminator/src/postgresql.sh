#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

terminator::__pragma__::once || return 0

function terminator::postgresql::__initialize__() {
  if ! command -v psql > /dev/null 2>&1; then
    terminator::log::warning 'postgresql is not installed'
    return
  fi

  alias psql_list_config='terminator::postgresql::list_config'
  alias psql_edit_config='terminator::postgresql::edit_config'
  alias psql_clear_pid='terminator::postgresql::clear_pid'
}

function terminator::postgresql::list_config() {
  psql -qAt -c 'show hba_file' | xargs grep -v -E '^[[:space:]]*#'
}

function terminator::postgresql::edit_config() {
  vim "$(psql -qAt  -c 'SHOW config_file')"
}

# from https://stackoverflow.com/questions/13573204/psql-could-not-connect-to-server-no-such-file-or-directory-mac-os-x
function terminator::postgresql::clear_pid() {
  if terminator::homebrew::package::is_installed postgresql; then
    local path file
    path="$(brew --prefix)/var"
    file="${path}/postgres/postmaster.pid"

    less "${path}/log/postgres.log"
    if terminator::utility::ask "move ${file}?"; then
      sudo mv "${file}" "${HOME}/"
    fi
  else
    terminator::log::warning \
      'homebrew is not installed' \
      'and/or postgres is not brew installed'
  fi
}
