############################################################
# .bashrc
############################################################
# If not running interactively, don't do anything
if [[ -n "$PS1" ]]; then
  source $HOME/.bash_func
  source_if_exists $HOME/.bash_styles

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
  export CSCOPE_EDITOR=$EDITOR
  export INPUTRC=$HOME/.inputrc

  export HSR="$HOME/.homesick/repos"
  initialize_cdpath "$HSR"

  if [ $(id -u) -eq 0 ]; then
    export UserColor="$IRed"
    export UserSeparator="#"
    export PathColor="$IBlue"
    source_if_exists $HOME/.bash_root_styles
  fi

  export PROMPT_COMMAND=full_ps1_info
fi

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
