#!/bin/bash

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/.terminator/src/source.sh"

  terminator::source "${HOME}/.terminator/src/prompt.sh"

  # append to the history file, don't overwrite it
  shopt -s histappend

  # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
  HISTSIZE=1000000
  HISTFILESIZE=2000000

  # don't put duplicate lines in the history. See bash(1) for more options
  # ... or force ignoredups and ignorespace
  HISTCONTROL=ignoredups:ignorespace

  # add timestamps to history
  export HISTTIMEFORMAT='%F %T '
  export HISTIGNORE="bg:fg"

  # no empty command completion
  shopt -s no_empty_cmd_completion

  # check the window size after each command and, if necessary,
  # update the values of LINES and COLUMNS.
  shopt -s checkwinsize

  shopt -s cdspell # cd spell guessing
  shopt -s cdable_vars # if path not found assumes is var

  # disable XON/XOFF so ctrl-s works for forward-searching
  stty -ixon

  export TERM='xterm-256color'
  export EDITOR=vim
  export CSCOPE_EDITOR="${EDITOR}"
  export INPUTRC="${HOME}/.inputrc"

  export HSR="${HOME}/.homesick/repos"
  terminator::cdpath::prepend "${HSR}"

  export TERMINATOR_GIT_STATUS_STASH_ENABLED=1

  # jenv uses PROMPT_COMMAND as a hook
  # which we have to preserve by chaining PROMPT_COMMAND
  export PROMPT_COMMAND="terminator::prompt;${PROMPT_COMMAND}"
fi
