#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/array.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/number.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/prompt/git.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/prompt/svn.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/ssh.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/string.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/styles.sh"

terminator::__module__::load || return 0

TERMINATOR_PROMPT_COMMAND_DEFAULT='terminator::prompt::full'
TERMINATOR_PROMPT_COMMANDS=(
  'terminator::prompt::minimal'
  'terminator::prompt::full'
)

# Dispatches to the prompt command set via TERMINATOR_PROMPT_COMMAND.
# Falls back to TERMINATOR_PROMPT_COMMAND_DEFAULT if command not found.
function terminator::prompt {
  local \
    last_command_exit=$? \
    cmd

  terminator::prompt::get cmd

  if terminator::command::exists "${cmd}"; then
    "${cmd}" "${last_command_exit}"
  else
    "${TERMINATOR_PROMPT_COMMAND_DEFAULT}" "${last_command_exit}"
  fi
}

# Returns the current prompt command, falling back to the default.
# Internal var uses __ prefix to avoid colliding with the caller's
# variable name when using printf -v to write to it.
function terminator::prompt::get {
  local __prompt_get_cmd__="${TERMINATOR_PROMPT_COMMAND:-${TERMINATOR_PROMPT_COMMAND_DEFAULT}}"

  case "$#" in
    1) printf -v "$1" '%s' "${__prompt_get_cmd__}" ;;
    *) echo "${__prompt_get_cmd__}" ;;
  esac
}

# Sets the prompt command with validation.
# Supports '-' to toggle to the previous prompt command (like cd -).
function terminator::prompt::set {
  local \
    new_cmd="$1" \
    current_cmd

  if [[ "${new_cmd}" == "-" ]]; then
    if [[ -z "${TERMINATOR_PROMPT_COMMAND_PREVIOUS}" ]]; then
      terminator::logger::warning 'no previous prompt command to toggle to'
      return 1
    fi
    new_cmd="${TERMINATOR_PROMPT_COMMAND_PREVIOUS}"
  fi

  if [[ -z "${new_cmd}" ]]; then
    terminator::logger::warning 'usage: terminator::prompt::set <command>'
    return 1
  fi

  if ! terminator::command::exists "${new_cmd}"; then
    terminator::logger::warning "'${new_cmd}' not found, keeping current prompt"
    return 1
  fi

  terminator::prompt::get current_cmd

  export TERMINATOR_PROMPT_COMMAND_PREVIOUS="${current_cmd}"
  export TERMINATOR_PROMPT_COMMAND="${new_cmd}"
}

# Registers prompt commands for tab completion.
# Accepts one or more command names. Skips duplicates.
# Warns and skips commands that do not exist.
function terminator::prompt::register {
  local cmd

  for cmd in "$@"; do
    if ! terminator::command::exists "${cmd}"; then
      terminator::logger::warning "'${cmd}' not found, skipping registration"
      continue
    fi

    if ! terminator::array::contains "${cmd}" "${TERMINATOR_PROMPT_COMMANDS[@]}"; then
      TERMINATOR_PROMPT_COMMANDS+=("${cmd}")
    fi
  done
}

# Tab completion for terminator::prompt::set and prompt-set.
#
# Bash treats ':' as a word break by default (via COMP_WORDBREAKS), so
# completing "terminator::prompt::" splits into multiple words and causes
# the prefix to be doubled.
#
# _get_comp_words_by_ref -n : rebuilds the full word ignoring colon splits,
# and __ltrim_colon_completions strips the already-typed colon prefix from
# each COMPREPLY entry.
#
# Both helpers come from the bash-completion package. If unavailable, falls
# back to basic completion without colon handling.
function terminator::prompt::completion {
  # Only complete the first argument.
  if ((COMP_CWORD > 1)); then
    return
  fi

  local cur

  if terminator::command::exists _get_comp_words_by_ref; then
    _get_comp_words_by_ref -n : cur
  else
    cur="${COMP_WORDS[COMP_CWORD]}"
  fi

  COMPREPLY=()

  while IFS='' read -r completion; do
    COMPREPLY+=("${completion}")
  done < <(compgen -W "${TERMINATOR_PROMPT_COMMANDS[*]}" -- "${cur}")

  if terminator::command::exists __ltrim_colon_completions; then
    __ltrim_colon_completions "${cur}"
  fi
}

# Minimal prompt with just the command symbol.
function terminator::prompt::minimal {
  local symbol

  terminator::styles::command_symbol symbol

  PS1="${symbol} "

  export PS1
}

# Full BASH PS1 prompt showing current GIT or SVN repository and branch
# with colorization to show status (red dirty/green clean).
function terminator::prompt::full {
  local last_command_exit="${1:-$?}" \
    left_prompt \
    right_prompt

  terminator::prompt::left "${last_command_exit}" left_prompt

  # TODO clip right prompt if left is too big?
  terminator::prompt::right "${last_command_exit}" right_prompt

  printf -v PS1 '%s\r%s' \
    "${right_prompt}" \
    "${left_prompt}"

  export PS1
}

function terminator::prompt::ask {
  echo -n "$*" '[y/n] '
  read -r response
  case "${response}" in
    y* | Y*) return 0 ;;
    *) return 1 ;;
  esac
}

function terminator::prompt::enable_env_tracing {
  PS4='+$BASH_SOURCE> ' BASH_XTRACEFD=7 bash -xl 7>&2
}

function terminator::prompt::left {
  local last_command_exit="${1:-$?}" \
    error_status \
    ssh_status \
    user_prefix \
    user \
    user_suffix \
    host_prefix \
    host \
    host_suffix \
    directory_prefix \
    directory \
    directory_suffix \
    jobs_info \
    timestamp \
    version_control \
    newline \
    command_symbol_prefix \
    command_symbol \
    command_symbol_suffix \
    color_off \
    left_prompt_buffer

  terminator::prompt::error "${last_command_exit}" error_status
  terminator::prompt::ssh ssh_status
  terminator::prompt::user_prefix user_prefix
  terminator::prompt::user user
  terminator::prompt::user_suffix user_suffix
  terminator::prompt::host_prefix host_prefix
  terminator::prompt::host host
  terminator::prompt::host_suffix host_suffix
  terminator::prompt::directory_prefix directory_prefix
  terminator::prompt::directory directory
  terminator::prompt::directory_suffix directory_suffix
  terminator::prompt::version_control version_control
  terminator::prompt::jobs_info jobs_info
  terminator::prompt::timestamp timestamp
  terminator::styles::newline newline
  terminator::prompt::command_symbol_prefix command_symbol_prefix
  terminator::prompt::command_symbol "${last_command_exit}" command_symbol
  terminator::prompt::command_symbol_suffix command_symbol_suffix
  terminator::color::off color_off

  printf -v left_prompt_buffer '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s' \
    "${error_status}" \
    "${ssh_status}" \
    "${user_prefix}" \
    "${user}" \
    "${user_suffix}" \
    "${host_prefix}" \
    "${host}" \
    "${host_suffix}" \
    "${directory_prefix}" \
    "${directory}" \
    "${directory_suffix}" \
    "${version_control}" \
    "${jobs_info}" \
    "${timestamp}" \
    "${newline}" \
    "${command_symbol_prefix}" \
    "${command_symbol}" \
    "${command_symbol_suffix}" \
    "${color_off}"

  terminator::prompt::print_if_exists \
    --content "${left_prompt_buffer}" \
    "${@:2}"
}

function terminator::prompt::right {
  local last_command_exit="${1:-$?}" \
    right_prompt_prefix \
    right_prompt_content \
    right_prompt_suffix \
    color_off \
    right_prompt_buffer \
    right_prompt_padding \
    sanitized_buffer \
    multi_byte_offset \
    total_offset

  terminator::prompt::right_prompt_prefix right_prompt_prefix
  terminator::prompt::right_prompt_content right_prompt_content
  terminator::prompt::right_prompt_suffix right_prompt_suffix
  terminator::color::off color_off

  printf -v right_prompt_buffer '%s%s%s%s' \
    "${right_prompt_prefix}" \
    "${right_prompt_content}" \
    "${right_prompt_suffix}" \
    "${color_off}"

  terminator::string::bytes_to_length_offset \
    --value "${right_prompt_buffer}" \
    --output multi_byte_offset

  terminator::string::strip_colors \
    --value "${right_prompt_buffer}" \
    --output sanitized_buffer

  total_offset="$((${#right_prompt_buffer} - ${#sanitized_buffer} + multi_byte_offset))"
  right_prompt_padding="$((COLUMNS + total_offset))"

  printf -v right_prompt_buffer '%*s' \
    "${right_prompt_padding}" \
    "${right_prompt_buffer}"

  terminator::prompt::print_if_exists \
    --content "${right_prompt_buffer}" \
    "${@:2}"
}

function terminator::prompt::error {
  local last_command_exit="${1:-$?}"

  if ((last_command_exit != 0)); then
    local error_color error_symbol

    terminator::styles::error_color error_color
    terminator::styles::error_symbol error_symbol

    terminator::prompt::print_if_exists \
      --color "${error_color}" \
      --content "${error_symbol}" \
      --right 1 \
      "${@:2}"
  fi
}

function terminator::prompt::ssh {
  if terminator::ssh::is_ssh_session; then
    local host_color host_symbol

    terminator::styles::host_color host_color
    terminator::styles::host_symbol host_symbol

    terminator::prompt::print_if_exists \
      --color "${host_color}" \
      --content "${host_symbol}" \
      --right 1 \
      "$@"
  fi
}

function terminator::prompt::user_prefix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_USER_PREFIX_COMMAND}" \
    --command terminator::prompt::static::user_prefix \
    "$@"
}

function terminator::prompt::static::user_prefix {
  local user_prefix_color user_prefix_content

  terminator::styles::user_prefix user_prefix_content
  terminator::styles::user_prefix_color user_prefix_color

  terminator::prompt::print_if_exists \
    --color "${user_prefix_color}" \
    --content "${user_prefix_content}" \
    "$@"
}

function terminator::prompt::user {
  local user_color username

  terminator::styles::user_color user_color
  terminator::styles::username username

  terminator::prompt::print_if_exists \
    --color "${user_color}" \
    --content "${username}" \
    "$@"
}

function terminator::prompt::user_suffix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_USER_SUFFIX_COMMAND}" \
    --command terminator::prompt::static::user_suffix \
    "$@"
}

function terminator::prompt::static::user_suffix {
  local user_suffix_color user_suffix_content

  terminator::styles::user_suffix user_suffix_content
  terminator::styles::user_suffix_color user_suffix_color

  terminator::prompt::print_if_exists \
    --color "${user_suffix_color}" \
    --content "${user_suffix_content}" \
    "$@"
}

function terminator::prompt::host_prefix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_HOST_PREFIX_COMMAND}" \
    --command terminator::prompt::static::host_prefix \
    "$@"
}

function terminator::prompt::static::host_prefix {
  local host_prefix_color host_prefix_content

  terminator::styles::host_prefix host_prefix_content
  terminator::styles::host_prefix_color host_prefix_color

  terminator::prompt::print_if_exists \
    --color "${host_prefix_color}" \
    --content "${host_prefix_content}" \
    "$@"
}

function terminator::prompt::host {
  local host_color hostname

  terminator::styles::host_color host_color
  terminator::styles::hostname hostname

  terminator::prompt::print_if_exists \
    --color "${host_color}" \
    --content "${hostname}" \
    "$@"
}

function terminator::prompt::host_suffix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_HOST_SUFFIX_COMMAND}" \
    --command terminator::prompt::static::host_suffix \
    "$@"
}

function terminator::prompt::static::host_suffix {
  local host_suffix_color host_suffix_content

  terminator::styles::host_suffix host_suffix_content
  terminator::styles::host_suffix_color host_suffix_color

  terminator::prompt::print_if_exists \
    --color "${host_suffix_color}" \
    --content "${host_suffix_content}" \
    "$@"
}

function terminator::prompt::directory_prefix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_DIRECTORY_PREFIX_COMMAND}" \
    --command terminator::prompt::static::directory_prefix \
    "$@"
}

function terminator::prompt::static::directory_prefix {
  local directory_prefix_color directory_prefix_content

  terminator::styles::directory_prefix directory_prefix_content
  terminator::styles::directory_prefix_color directory_prefix_color

  terminator::prompt::print_if_exists \
    --color "${directory_prefix_color}" \
    --content "${directory_prefix_content}" \
    "$@"
}

function terminator::prompt::directory {
  local directory_path_color directory_path_content

  terminator::styles::directory_color directory_path_color
  terminator::styles::directory directory_path_content

  terminator::prompt::print_if_exists \
    --color "${directory_path_color}" \
    --content "${directory_path_content}" \
    "$@"
}

function terminator::prompt::directory_suffix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_DIRECTORY_SUFFIX_COMMAND}" \
    --command terminator::prompt::static::directory_suffix \
    "$@"
}

function terminator::prompt::static::directory_suffix {
  local directory_suffix_color directory_suffix_content

  terminator::styles::directory_suffix directory_suffix_content
  terminator::styles::directory_suffix_color directory_suffix_color

  terminator::prompt::print_if_exists \
    --color "${directory_suffix_color}" \
    --content "${directory_suffix_content}" \
    "$@"
}

function terminator::prompt::version_control {
  local svn_status git_status

  # terminator::prompt::svn svn_status
  terminator::prompt::git git_status

  terminator::prompt::print_if_exists \
    --content "${svn_status}${git_status}" \
    --right 1 \
    "$@"
}

function terminator::prompt::jobs_info {
  local jobs_symbol_color \
    jobs_symbol \
    jobs_content \
    enclosure_color \
    color_off

  terminator::styles::jobs jobs_symbol
  terminator::styles::ok_color jobs_symbol_color
  terminator::styles::enclosure_color enclosure_color
  terminator::color::off color_off

  printf -v jobs_content '%s%s%s%s' \
    "${enclosure_color}{${color_off}" \
    "${jobs_symbol_color}" \
    "${jobs_symbol}" \
    "${enclosure_color}}${color_off}"

  terminator::prompt::print_if_exists \
    --content "${jobs_content}" \
    "$@"
}

function terminator::prompt::timestamp {
  local timestamp_symbol_color \
    timestamp_symbol \
    timestamp_content \
    enclosure_color \
    color_off

  terminator::styles::timestamp timestamp_symbol
  terminator::styles::enclosure_color timestamp_symbol_color
  terminator::styles::enclosure_color enclosure_color
  terminator::color::off color_off

  printf -v timestamp_content '%s%s%s%s' \
    "${enclosure_color}(${color_off}" \
    "${timestamp_symbol_color}" \
    "${timestamp_symbol}" \
    "${enclosure_color})${color_off}"

  terminator::prompt::print_if_exists \
    --content "${timestamp_content}" \
    --left 1 \
    "$@"
}

function terminator::prompt::command_symbol_prefix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX_COMMAND}" \
    --command terminator::prompt::static::command_symbol_prefix \
    "$@"
}

function terminator::prompt::static::command_symbol_prefix {
  local command_symbol_prefix_color command_symbol_prefix_content

  terminator::styles::command_symbol_prefix command_symbol_prefix_content
  terminator::styles::command_symbol_prefix_color command_symbol_prefix_color

  terminator::prompt::print_if_exists \
    --color "${command_symbol_prefix_color}" \
    --content "${command_symbol_prefix_content}" \
    "$@"
}

function terminator::prompt::command_symbol {
  local last_command_exit="${1:-$?}" \
    command_symbol_color \
    command_symbol_

  terminator::styles::command_symbol command_symbol_

  if ((last_command_exit != 0)); then
    terminator::styles::error_color command_symbol_color
  # else
  #   terminator::styles::ok_color command_symbol_color
  fi

  terminator::prompt::print_if_exists \
    --color "${command_symbol_color}" \
    --content "${command_symbol_}" \
    "${@:2}"
}

function terminator::prompt::command_symbol_suffix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX_COMMAND}" \
    --command terminator::prompt::static::command_symbol_suffix \
    "$@"
}

function terminator::prompt::static::command_symbol_suffix {
  local command_symbol_suffix_color command_symbol_suffix_content

  terminator::styles::command_symbol_suffix command_symbol_suffix_content
  terminator::styles::command_symbol_suffix_color command_symbol_suffix_color

  terminator::prompt::print_if_exists \
    --color "${command_symbol_suffix_color}" \
    --content "${command_symbol_suffix_content}" \
    "$@"
}

function terminator::prompt::right_prompt_prefix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX_COMMAND}" \
    --command terminator::prompt::static::right_prompt_prefix \
    "$@"
}

function terminator::prompt::static::right_prompt_prefix {
  local right_prompt_prefix_color right_prompt_prefix_content

  terminator::styles::right_prompt_prefix right_prompt_prefix_content
  terminator::styles::right_prompt_prefix_color right_prompt_prefix_color

  terminator::prompt::print_if_exists \
    --color "${right_prompt_prefix_color}" \
    --content "${right_prompt_prefix_content}" \
    "$@"
}

function terminator::prompt::right_prompt_content {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT_COMMAND}" \
    --command terminator::prompt::static::right_prompt_content \
    "$@"
}

function terminator::prompt::static::right_prompt_content {
  local right_prompt_content_color right_prompt_content_content

  terminator::styles::right_prompt_content right_prompt_content_content
  terminator::styles::right_prompt_content_color right_prompt_content_color

  terminator::prompt::print_if_exists \
    --color "${right_prompt_content_color}" \
    --content "${right_prompt_content_content}" \
    "$@"
}

function terminator::prompt::right_prompt_suffix {
  terminator::styles::command_coalesce \
    --command "${TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX_COMMAND}" \
    --command terminator::prompt::static::right_prompt_suffix \
    "$@"
}

function terminator::prompt::static::right_prompt_suffix {
  local right_prompt_suffix_color right_prompt_suffix_content

  terminator::styles::right_prompt_suffix right_prompt_suffix_content
  terminator::styles::right_prompt_suffix_color right_prompt_suffix_color

  terminator::prompt::print_if_exists \
    --color "${right_prompt_suffix_color}" \
    --content "${right_prompt_suffix_content}" \
    "$@"
}

function terminator::prompt::print_if_exists {
  local message_color \
    message_content \
    color_off \
    left_padding=0 \
    right_padding=0 \
    left_padding_content \
    right_padding_content \
    output \
    help_command=terminator::prompt::print_if_exists::usage

  while (($# != 0)); do
    case "$1" in
      -h | --help)
        "${help_command}"
        return 0
        ;;
      -c | --content)
        shift
        message_content="$1"
        ;;
      -k | --color)
        shift
        message_color="$1"
        ;;
      -l | --left)
        shift
        left_padding="$1"
        ;;
      -r | --right)
        shift
        right_padding="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      -*)
        terminator::logger::error "invalid option: '$1'"
        "${help_command}"
        return 1
        ;;
      *)
        if [[ -z "${output}" ]]; then
          output="$1"
        fi
        ;;
    esac
    shift
  done

  if ! terminator::number::is_unsigned_integer "${left_padding}"; then
    terminator::logger::error "invalid value left_padding: '${left_padding}' is not an unsigned integer"
    "${help_command}"
    return 1
  fi

  if ! terminator::number::is_unsigned_integer "${right_padding}"; then
    terminator::logger::error "invalid value right_padding: '${right_padding}' is not an unsigned integer"
    "${help_command}"
    return 1
  fi

  if [[ -n "${message_content}" ]]; then
    terminator::color::off color_off

    terminator::string::repeat \
      --value ' ' \
      --count "${left_padding}" \
      --output left_padding_content

    terminator::string::repeat \
      --value ' ' \
      --count "${right_padding}" \
      --output right_padding_content

    if [[ -n "${output}" ]]; then
      printf -v "${output}" '%s%s%s%s%s' \
        "${left_padding_content}" \
        "${message_color}" \
        "${message_content}" \
        "${color_off}" \
        "${right_padding_content}"
      return
    fi

    printf '%s%s%s%s%s' \
      "${left_padding_content}" \
      "${message_color}" \
      "${message_content}" \
      "${color_off}" \
      "${right_padding_content}"
  fi
}

function terminator::prompt::print_if_exists::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [ouput variable]

  -c, --content      Content of message.
                     Will not print anything if empty

  -k, --color        Color of message

  -l, --left         Left padding amount.
                     Must be valid unsigned integer.
                     Default: 0

  -r, --right        Right padding amount.
                     Must be valid unsigned integer.
                     Default: 0

  -o, --output       Variable to write output to.
                     Will use argument if specified and if flag is not used.
                     If not specified will write output to stdout

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::prompt::__export__ {
  export -f terminator::prompt
  export -f terminator::prompt::get
  export -f terminator::prompt::set
  export -f terminator::prompt::register
  export -f terminator::prompt::completion
  export -f terminator::prompt::minimal
  export -f terminator::prompt::full
  export -f terminator::prompt::ask
  export -f terminator::prompt::enable_env_tracing
  export -f terminator::prompt::left
  export -f terminator::prompt::right
  export -f terminator::prompt::error
  export -f terminator::prompt::ssh
  export -f terminator::prompt::user_prefix
  export -f terminator::prompt::static::user_prefix
  export -f terminator::prompt::user
  export -f terminator::prompt::user_suffix
  export -f terminator::prompt::static::user_suffix
  export -f terminator::prompt::host_prefix
  export -f terminator::prompt::static::host_prefix
  export -f terminator::prompt::host
  export -f terminator::prompt::host_suffix
  export -f terminator::prompt::static::host_suffix
  export -f terminator::prompt::directory_prefix
  export -f terminator::prompt::static::directory_prefix
  export -f terminator::prompt::directory
  export -f terminator::prompt::directory_suffix
  export -f terminator::prompt::static::directory_suffix
  export -f terminator::prompt::version_control
  export -f terminator::prompt::jobs_info
  export -f terminator::prompt::timestamp
  export -f terminator::prompt::command_symbol_prefix
  export -f terminator::prompt::static::command_symbol_prefix
  export -f terminator::prompt::command_symbol
  export -f terminator::prompt::command_symbol_suffix
  export -f terminator::prompt::static::command_symbol_suffix
  export -f terminator::prompt::right_prompt_prefix
  export -f terminator::prompt::static::right_prompt_prefix
  export -f terminator::prompt::right_prompt_content
  export -f terminator::prompt::static::right_prompt_content
  export -f terminator::prompt::right_prompt_suffix
  export -f terminator::prompt::static::right_prompt_suffix
  export -f terminator::prompt::print_if_exists
  export -f terminator::prompt::print_if_exists::usage

  alias prompt-set='terminator::prompt::set'

  complete -F terminator::prompt::completion prompt-set
}

# KCOV_EXCL_START
function terminator::prompt::__recall__ {
  export -fn terminator::prompt
  export -fn terminator::prompt::get
  export -fn terminator::prompt::set
  export -fn terminator::prompt::register
  export -fn terminator::prompt::completion
  export -fn terminator::prompt::minimal
  export -fn terminator::prompt::full
  export -fn terminator::prompt::ask
  export -fn terminator::prompt::enable_env_tracing
  export -fn terminator::prompt::left
  export -fn terminator::prompt::right
  export -fn terminator::prompt::error
  export -fn terminator::prompt::ssh
  export -fn terminator::prompt::user_prefix
  export -fn terminator::prompt::static::user_prefix
  export -fn terminator::prompt::user
  export -fn terminator::prompt::user_suffix
  export -fn terminator::prompt::static::user_suffix
  export -fn terminator::prompt::host_prefix
  export -fn terminator::prompt::static::host_prefix
  export -fn terminator::prompt::host
  export -fn terminator::prompt::host_suffix
  export -fn terminator::prompt::static::host_suffix
  export -fn terminator::prompt::directory_prefix
  export -fn terminator::prompt::static::directory_prefix
  export -fn terminator::prompt::directory
  export -fn terminator::prompt::directory_suffix
  export -fn terminator::prompt::static::directory_suffix
  export -fn terminator::prompt::version_control
  export -fn terminator::prompt::jobs_info
  export -fn terminator::prompt::timestamp
  export -fn terminator::prompt::command_symbol_prefix
  export -fn terminator::prompt::static::command_symbol_prefix
  export -fn terminator::prompt::command_symbol
  export -fn terminator::prompt::command_symbol_suffix
  export -fn terminator::prompt::static::command_symbol_suffix
  export -fn terminator::prompt::right_prompt_prefix
  export -fn terminator::prompt::static::right_prompt_prefix
  export -fn terminator::prompt::right_prompt_content
  export -fn terminator::prompt::static::right_prompt_content
  export -fn terminator::prompt::right_prompt_suffix
  export -fn terminator::prompt::static::right_prompt_suffix
  export -fn terminator::prompt::print_if_exists
  export -fn terminator::prompt::print_if_exists::usage

  unalias prompt-set

  complete -r prompt-set 2>/dev/null
}
# KCOV_EXCL_STOP

terminator::__module__::export
