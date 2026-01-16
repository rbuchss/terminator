#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

terminator::__module__::load || return 0

function terminator::vim::__enable__ {
  terminator::command::any_exist -v nvim vim || return

  alias vi='terminator::vim::invoke'
  alias vim='terminator::vim::invoke'
  alias vf='terminator::vim::open::filename_match'
  alias vg='terminator::vim::open::content_match'
  alias vd='terminator::vim::open::git_diff'

  # Sets up completion for git branches
  if declare -F __git_complete > /dev/null 2>&1; then
    __git_complete vd _git_checkout
  fi

  terminator::vim::set_editor
}

function terminator::vim::__disable__ {
  unalias vi
  unalias vim
  unalias vf
  unalias vg
  unalias vd

  # __git_complete uses complete under the hood so using
  #   complete -r to remove
  # ref:
  #   https://github.com/git/git/blob/e79552d19784ee7f4bbce278fe25f93fbda196fa/contrib/completion/git-completion.bash#L3741-L3747
  complete -r vd

  terminator::vim::unset_editor
}

function terminator::vim::get_command {
  local vim_command \
    vim_commands=(
      nvim
      vim
    )

  for vim_command in "${vim_commands[@]}"; do
    if declare -F terminator::logger::debug > /dev/null 2>&1; then
      terminator::logger::debug "Trying to use vim command: ${vim_command}"
    fi

    if command -v "${vim_command}" > /dev/null 2>&1; then
      if declare -F terminator::logger::debug > /dev/null 2>&1; then
        terminator::logger::debug "Found vim command: ${vim_command}"
      fi

      echo "${vim_command}"
      return 0
    fi
  done

  terminator::logger::error "No possible vim commands found: [${vim_commands[*]}]"
  return 1
}

function terminator::vim::set_editor {
  local vim_command

  vim_command="$(terminator::vim::get_command)" || return 1

  export EDITOR="${vim_command}"
  export CSCOPE_EDITOR="${vim_command}"

  if declare -F terminator::logger::debug > /dev/null 2>&1; then
    terminator::logger::debug "Set EDITOR and CSCOPE_EDITOR to: ${vim_command}"
  fi
}

function terminator::vim::unset_editor {
  unset EDITOR
  unset CSCOPE_EDITOR

  if declare -F terminator::logger::debug > /dev/null 2>&1; then
    terminator::logger::debug "Unset EDITOR and CSCOPE_EDITOR"
  fi
}

function terminator::vim::invoke {
  local vim_command

  vim_command="$(terminator::vim::get_command)" || return 1

  command "${vim_command}" "$@"
}

function terminator::vim::open::filename_match {
  local found_command=0 \
    search_command \
    search_commands=(
      'rg'
      'ag'
      'ack'
      'find'
    )

  for search_command in "${search_commands[@]}"; do
    terminator::logger::debug "Trying to search with command: ${search_command}"

    if command -v "${search_command}" > /dev/null 2>&1; then
      terminator::logger::debug "Found search command: ${search_command}"

      found_command=1

      # using subshell to invoke exported wrapper function - see shellcheck SC2033.
      # vim expects tty to be attached and will not work without.
      # ${FUNCNAME[0]} is a placeholder for the $0 var and without we'd lose the first file passed to vim.
      "terminator::vim::open::filename_match::${search_command}" "$@" \
        | xargs -0 bash -c 'terminator::vim::invoke -p "$@" < /dev/tty' "${FUNCNAME[0]}"

      break
    fi
  done

  if (( found_command == 0 )); then
    terminator::logger::error "No possible search commands found: [${search_commands[*]}]"
    return 1
  fi
}

function terminator::vim::open::filename_match::rg {
  command rg \
    --files \
    --hidden \
    --null \
    "${2:-./}" \
    | command rg \
      --null-data \
      --smart-case \
      "$1" \
    | sort -z
}

function terminator::vim::open::filename_match::ag {
  command ag \
    --hidden \
    --smart-case \
    --null \
    -g "$1" \
    "${2:-./}" \
    | sort -z
}

function terminator::vim::open::filename_match::ack {
  command ack \
    --ignore-dir=.git \
    --smart-case \
    --print0 \
    -g "$1" \
    "${2:-./}" \
    | sort -z
}

function terminator::vim::open::filename_match::find {
  command find "${2:-.}" \
    -not \( -path "${2:-.}/.git" -prune \) \
    -type f \
    -regex ".*$1.*" \
    -print0 \
    | sort -z
}

function terminator::vim::open::content_match {
  local found_command=0 \
    search_command \
    search_commands=(
      'rg'
      'ag'
      'ack'
      'grep'
    )

  for search_command in "${search_commands[@]}"; do
    terminator::logger::debug "Trying to search with command: ${search_command}"

    if command -v "${search_command}" > /dev/null 2>&1; then
      terminator::logger::debug "Found search command: ${search_command}"

      found_command=1

      # using subshell to invoke exported wrapper function - see shellcheck SC2033.
      # vim expects tty to be attached and will not work without.
      # ${FUNCNAME[0]} is a placeholder for the $0 var and without we'd lose the first file passed to vim.
      "terminator::vim::open::content_match::${search_command}" "$@" \
        | xargs -0 bash -c 'terminator::vim::invoke -p "$@" < /dev/tty' "${FUNCNAME[0]}"

      break
    fi
  done

  if (( found_command == 0 )); then
    terminator::logger::error "No possible search commands found: [${search_commands[*]}]"
    return 1
  fi
}

function terminator::vim::open::content_match::rg {
  command rg \
    --hidden \
    --smart-case \
    -l \
    --null \
    "$1" \
    "${2:-./}" \
    | sort -z
}

function terminator::vim::open::content_match::ag {
  command ag \
    --hidden \
    --smart-case \
    -l \
    --null \
    "$1" \
    "${2:-./}" \
    | sort -z
}

function terminator::vim::open::content_match::ack {
  command ack \
    --ignore-dir=.git \
    --smart-case \
    -l \
    --print0 \
    "$1" \
    "${2:-./}" \
    | sort -z
}

function terminator::vim::open::content_match::grep {
  command grep \
    -R \
    --exclude-dir=.git \
    -l \
    --null \
    "$1" \
    "${2:-./}" \
    | sort -z
}

function terminator::vim::open::git_diff {
  local found_ref=0 \
    ref \
    root_dir \
    option_read_mode='REF' \
    refs=() \
    path_params=() \
    default_refs=(
      'HEAD'
      'HEAD^!'
    )

    while (( $# != 0 )); do
      case "$1" in
        --)
          option_read_mode='PATH'
          ;;
        *)
          if [[ "${option_read_mode}" == 'PATH' ]]; then
            path_params+=("$1")
          else
            refs+=("$1")
          fi
          ;;
      esac
      shift
    done

  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    terminator::logger::error "Not in git repo!"
    return 1
  fi

  root_dir="$(git rev-parse --show-toplevel)"

  if (( ${#refs[@]} > 0 )); then
    terminator::logger::debug "Using refs specified: [${refs[*]}]"
  else
    terminator::logger::debug "No refs specified - Using defaults: [${default_refs[*]}]"
    refs=("${default_refs[@]}")
  fi

  terminator::logger::debug "Using git paths specified: [${path_params[*]}]"

  for ref in "${refs[@]}"; do
    terminator::logger::debug "Trying to find git diff with ref: ${ref}"

    if ! command git diff \
        --name-only \
        --exit-code \
        "${ref}" \
        -- "${path_params[@]}" \
        > /dev/null 2>&1; then
      terminator::logger::debug "Found git diff with ref: ${ref}"

      found_ref=1

      # using subshell to invoke exported wrapper function - see shellcheck SC2033.
      # vim expects tty to be attached and will not work without.
      # ${root_dir} is a placeholder for the $0 var and without we'd lose the first file passed to vim.
      # Note that the ${root_dir} placeholder is also used to change to the repo root directory prior
      # to opening these files. This is to avoid the issue when the cwd is not the repo root directory.
      # Without this, usage of this command outside of the root directory would fail to open those files
      # since git diff provides names relative to the repo root.
      # shellcheck disable=SC2016
      command git diff \
        --name-only -z \
        "${ref}" \
        -- "${path_params[@]}" \
        | xargs -0 bash -c 'cd "$0" && terminator::vim::invoke -p "$@" < /dev/tty' "${root_dir}"

      break
    fi
  done

  if (( found_ref == 0 )); then
    terminator::logger::error "No possible git diff refs found: [${refs[*]}]"
    return 1
  fi
}

function terminator::vim::__export__ {
  export -f terminator::vim::get_command
  export -f terminator::vim::set_editor
  export -f terminator::vim::unset_editor
  export -f terminator::vim::invoke
  export -f terminator::vim::open::filename_match
  export -f terminator::vim::open::filename_match::rg
  export -f terminator::vim::open::filename_match::ag
  export -f terminator::vim::open::filename_match::ack
  export -f terminator::vim::open::filename_match::find
  export -f terminator::vim::open::content_match
  export -f terminator::vim::open::content_match::rg
  export -f terminator::vim::open::content_match::ag
  export -f terminator::vim::open::content_match::ack
  export -f terminator::vim::open::content_match::grep
  export -f terminator::vim::open::git_diff
}

function terminator::vim::__recall__ {
  export -fn terminator::vim::get_command
  export -fn terminator::vim::set_editor
  export -fn terminator::vim::unset_editor
  export -fn terminator::vim::invoke
  export -fn terminator::vim::open::filename_match
  export -fn terminator::vim::open::filename_match::rg
  export -fn terminator::vim::open::filename_match::ag
  export -fn terminator::vim::open::filename_match::ack
  export -fn terminator::vim::open::filename_match::find
  export -fn terminator::vim::open::content_match
  export -fn terminator::vim::open::content_match::rg
  export -fn terminator::vim::open::content_match::ag
  export -fn terminator::vim::open::content_match::ack
  export -fn terminator::vim::open::content_match::grep
  export -fn terminator::vim::open::git_diff
}

terminator::__module__::export
