############################################################
# .bash_profile
############################################################
export debug_source=false
# load helper functions (Includes source_if_exists)
source $HOME/.bash_func

# prevents duplicated path created when using tmux
# by clearing out the old path and then rebuilding it
# like a brand new login shell
# will not do this if bash_login has already been run
if [[ ! -z $TMUX ]] && [[ -z $tmux_path_initialized ]]; then
  if_debug_echo 'initializing tmux...'
  PATH=""
  CDPATH=""
  MANPATH=""
  source /etc/profile
  export tmux_path_initialized=true
  export path_initialized=
fi

initialize_path "$HOME/bin:$HOME/bin-terminator"
initialize_cdpath "$HOME:/opt"

# OS specific features
if [[ 'Darwin' == `uname` ]]; then
  # using GNU for coreutils vs BSD
  add_brew_paths coreutils gnu-sed

  # gotta have dircolors
  eval `dircolors $HOME/.dir_colors`

  export my_services="$HOME/Library/Services/"
  initialize_cdpath "$my_services"

  source_if_exists $(brew --prefix)/etc/bash_completion
  source_if_exists $(brew --prefix grc)/etc/grc.bashrc
elif [[ 'Linux' == `uname` ]]; then
  # make caps lock actually useful (in linux)
  if command -v xmodmap >/dev/null 2>&1; then
    xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'
  fi

  # enable bash completion in interactive shells
  source_if_exists /etc/bash_completion
  source_if_exists $HOME/git-prompt.sh $HOME/git-completion.bash
fi

# Source global definitions
source_if_exists $HOME/.bash_styles
source_if_exists $HOME/.bashrc
source_if_exists $HOME/.bash_aliases
source_if_exists $HOME/.tmux/helpers/tmuxinator.bash

# If not running interactively, don't do anything
if [[ -n "$PS1" ]]; then
  # use homeshick to manage dot-files
  source_if_exists $HSR/homeshick/homeshick.sh
  source_if_exists $HSR/homeshick/completions/homeshick-completion.bash
fi

# autoload other bash configs
for autoload_file in `ls -a $HOME/.bash_autoload* 2>/dev/null`; do
  source_if_exists $autoload_file
done

# ensure CDPATH has . as first element
initialize_cdpath '.'

# bootstrap pyenv
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  source "$(brew --prefix pyenv)/completions/pyenv.bash"
fi

# bootstrap rbenv
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)" >/dev/null
  source "$(brew --prefix rbenv)/completions/rbenv.bash"
fi

# bootstrap jenv
if command -v jenv 1>/dev/null 2>&1; then
  # export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
fi

if_debug_echo "Profile PATH: $PATH"
if_debug_echo "Profile MANPATH: $MANPATH"
if_debug_echo "Profile CDPATH: $CDPATH"
export path_initialized=true
export PATH
