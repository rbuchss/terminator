#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/array.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/prompt.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/vim.sh"

terminator::__module__::load || return 0

function terminator::myjournal::__enable__ {
  alias myjournal='terminator::myjournal::invoke'
  alias mj='terminator::myjournal::invoke'

  terminator::myjournal::completion::add_alias \
    'myjournal' \
    'mj'
}

function terminator::myjournal::__disable__ {
  unalias myjournal
  unalias mj

  terminator::myjournal::completion::remove_alias \
    'myjournal' \
    'mj'
}

function terminator::myjournal::invoke {
  local journal_dir \
    journal_file \
    journal_filepath \
    journal_files=("$@") \
    journal_filepaths=() \
    default_journal_files=("$(date +'%Y/%m/%d')")

  journal_dir="$(terminator::myjournal::root_dir)"

  if (( ${#journal_files[@]} > 0 )); then
    terminator::logger::debug "Using journal files specified: [${journal_files[*]}]"

    # Convert any keywords (today, tomorrow, yesterday) to dates
    local \
      file \
      converted_files=()

    for file in "${journal_files[@]}"; do
      converted_files+=("$(terminator::myjournal::convert_keyword_to_date "${file}")")
    done

    journal_files=("${converted_files[@]}")

    terminator::logger::debug "After conversion: [${journal_files[*]}]"
  else
    terminator::logger::debug "No journal files specified - Using defaults: [${default_journal_files[*]}]"
    journal_files=("${default_journal_files[@]}")
  fi

  for journal_file in "${journal_files[@]}"; do
    journal_filepath="${journal_dir}/${journal_file}.md"

    if ! terminator::myjournal::valid_name "${journal_file}"; then
      terminator::logger::error "Name '${journal_file}' is not valid!"
      return 1
    fi

    if [[ -f "${journal_filepath}" ]]; then
      journal_filepaths+=("${journal_filepath}")
    elif terminator::prompt::ask "Create new journal entry at: '${journal_filepath}' ?" \
        && terminator::myjournal::new_entry "${journal_filepath}"; then
      journal_filepaths+=("${journal_filepath}")
    fi
  done

  if (( ${#journal_filepaths[@]} == 0 )); then
    terminator::logger::error 'No valid journal files specified!'
    return 1
  fi

  terminator::logger::debug "Opening journal files: [${journal_filepaths[*]}]"
  terminator::vim::invoke -O "${journal_filepaths[@]}"
}

function terminator::myjournal::root_dir {
  echo "${TERMINATOR_MYJOURNAL_DIR:-${HOME}/vaults/chronicle/Journal}"
}

function terminator::myjournal::valid_name {
  local journal_name="$1"

  # Allow special keywords (they get converted to dates)
  case "${journal_name}" in
    today|tomorrow|yesterday)
      return 0
      ;;
  esac

  # Validate date format YYYY/MM/DD
  [[ "${journal_name}" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}$ ]]
}

function terminator::myjournal::convert_keyword_to_date {
  local keyword="$1"

  case "${keyword}" in
    today)
      date +'%Y/%m/%d'
      ;;
    tomorrow)
      # GNU date (Linux) vs BSD date (macOS) compatibility
      if date -d '+1 day' +'%Y/%m/%d' 2>/dev/null; then
        : # GNU date worked, already output
      else
        date -v+1d +'%Y/%m/%d' 2>/dev/null
      fi
      ;;
    yesterday)
      # GNU date (Linux) vs BSD date (macOS) compatibility
      if date -d '-1 day' +'%Y/%m/%d' 2>/dev/null; then
        : # GNU date worked, already output
      else
        date -v-1d +'%Y/%m/%d' 2>/dev/null
      fi
      ;;
    *)
      echo "${keyword}"
      ;;
  esac
}

function terminator::myjournal::template {
  local journal_name="$1"

  terminator::logger::debug "Generating template for journal entry: '${journal_name}'"

  if ! terminator::myjournal::valid_name "${journal_name}"; then
    terminator::logger::error "Name '${journal_name}' is not valid!"
    return 1
  fi

  # Convert YYYY/MM/DD to YYYY-MM-DD for date parsing
  local date_str="${journal_name//\//-}"

  cat <<EOF
---
id: ${date_str}
aliases: []
tags:
  - Journal
  - daily-notes
---
EOF
}

function terminator::myjournal::new_entry {
  local journal_filepath="$1"

  if [[ -z "${journal_filepath}" ]]; then
    terminator::logger::error 'No new journal entry filepath specified'
    return 1
  fi

  terminator::logger::debug "Creating new journal entry at: '${journal_filepath}'"

  local journal_dir="${journal_filepath%/*}"

  if [[ ! -d "${journal_dir}" ]]; then
    terminator::logger::debug "Creating a new journal dir at: '${journal_dir}'"

    if mkdir -p "${journal_dir}"; then
      terminator::logger::debug "Created a new journal dir at: '${journal_dir}'"
    else
      terminator::logger::error "Failed to create a new journal dir at: '${journal_dir}'"
      return 1
    fi
  fi

  local journal_subdir="${journal_dir##*/}" \
    journal_filename="${journal_filepath##*/}"

  local journal_name="${journal_subdir}/${journal_filename%%.*}" \
    journal_content

  if journal_content="$(terminator::myjournal::template "${journal_name}")" \
      && cat <<< "${journal_content}" > "${journal_filepath}"; then
    terminator::logger::info "Created a new journal entry at: '${journal_filepath}'"
  else
    terminator::logger::error "Failed to create a new journal entry at: '${journal_filepath}'"
    return 1
  fi
}

function terminator::myjournal::completion {
  local journal_dir \
    word="${COMP_WORDS[COMP_CWORD]}"

  journal_dir="$(terminator::myjournal::root_dir)"

  local suggestions=(
      "$(find "${journal_dir}" \
        -type f \
        -name '*.md' \
        -mindepth 2 \
        | sed -E "s%${journal_dir}/(.+).md%\1%")"
      )

  # Add special keywords (converted to dates)
  suggestions+=('today' 'tomorrow' 'yesterday')

  COMPREPLY=()

  while IFS='' read -r completion; do
    # This filters out already matched completions
    if ! terminator::array::contains "${completion}" "${COMP_WORDS[@]}"; then
      COMPREPLY+=("${completion}")
    fi
  done < <(compgen -W "${suggestions[*]}" -- "${word}")
}

function terminator::myjournal::completion::add_alias {
  local name
  for name in "$@"; do
    complete -F terminator::myjournal::completion "${name}"
  done
}

function terminator::myjournal::completion::remove_alias {
  local name
  for name in "$@"; do
    complete -r "${name}"
  done
}

function terminator::myjournal::__export__ {
  export -f terminator::myjournal::invoke
  export -f terminator::myjournal::root_dir
  export -f terminator::myjournal::valid_name
  export -f terminator::myjournal::convert_keyword_to_date
  export -f terminator::myjournal::template
  export -f terminator::myjournal::new_entry
  export -f terminator::myjournal::completion
  export -f terminator::myjournal::completion::add_alias
  export -f terminator::myjournal::completion::remove_alias
}

function terminator::myjournal::__recall__ {
  export -fn terminator::myjournal::invoke
  export -fn terminator::myjournal::root_dir
  export -fn terminator::myjournal::valid_name
  export -fn terminator::myjournal::convert_keyword_to_date
  export -fn terminator::myjournal::template
  export -fn terminator::myjournal::new_entry
  export -fn terminator::myjournal::completion
  export -fn terminator::myjournal::completion::add_alias
  export -fn terminator::myjournal::completion::remove_alias
}

terminator::__module__::export
