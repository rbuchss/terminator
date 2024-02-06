#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::mysql::__enable__ {
  terminator::command::exists -v mysql || return

  alias mysql='terminator::mysql::invoke'
  alias mysql_spl='terminator::mysql::show_process_list'
  alias mysql_find_column='terminator::mysql::find_column'
}

function terminator::mysql::__disable__ {
  unalias mysql
  unalias mysql_spl
  unalias mysql_find_column
}

function terminator::mysql::show_process_list {
  command mysql -e 'show processlist' | grep -E "$1"
}

function terminator::mysql::find_column {
  if (( $# != 2 )); then
    >&2 echo "ERROR: invalid # of args"
    >&2 echo "Usage: ${FUNCNAME[0]}: database column"
    return 65
  fi

  echo "${FUNCNAME[0]}: searching database: '$1' for column: '$2'"

  command mysql -e "SELECT TABLE_SCHEMA, TABLE_NAME, \
    group_concat(COLUMN_NAME) MATCHING_COLUMNS \
    FROM INFORMATION_SCHEMA.COLUMNS \
    WHERE COLUMN_NAME regexp '$2' \
      and TABLE_SCHEMA regexp '$1' \
    group by 1, 2;"
}

# actually show real hostname in prompt
# even if a localhost connection
function terminator::mysql::invoke {
  local host arguments=("$@")
  host="$(hostname -s)"

  for argument in "${arguments[@]}"; do
    if [[ "${argument}" =~ ^(--host|-h)$ ]]; then
      host='\h'
      break
    fi
  done

  export MYSQL_PS1="[mysql] \u@${host}:\d> "

  if command -v grcat > /dev/null 2>&1; then
    arguments+=("--pager="'grcat conf.sql'"")
  fi

  command mysql "${arguments[@]}"
}

function terminator::mysql::__export__ {
  export -f terminator::mysql::show_process_list
  export -f terminator::mysql::find_column
  export -f terminator::mysql::invoke
}

function terminator::mysql::__recall__ {
  export -fn terminator::mysql::show_process_list
  export -fn terminator::mysql::find_column
  export -fn terminator::mysql::invoke
}

terminator::__module__::export
