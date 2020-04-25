#!/bin/bash

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/.terminator/src/source.sh"

  terminator::source "${HOME}/.terminator/src/git.sh"
  terminator::source "${HOME}/.terminator/src/grep.sh"
  terminator::source "${HOME}/.terminator/src/vim.sh"

  # bash helpers
  alias sbp='terminator::source "${HOME}/.bash_profile"'
  alias clr='clear'
  alias df='df -kTh'
  alias du='du -kh'
  alias hideme='history -d $((HISTCMD-1)) &&'

  # safety first!
  alias rm='rm -i'
  alias mv='mv -i'
  alias cp='cp -i'

  # ls helpers
  alias ls='ls --color=auto'
  alias l='ls -CF'
  alias la='ls -a'
  alias ll='ls -lkh'
  alias lla='ll -a'
  alias lrt='ll -rt'
  alias lrta='lrt -a'
  alias lrtr='lrt -R'
  alias lrs='ll -rS'
  alias lrsa='lrs -a'
  alias lrsr='lrs -R'
  alias lr='ls -R'
  alias llr='ll -R'
  alias llra='llr -a'

  # file helpers
  alias t1='tail -n1'
  alias h1='head -n1'
  alias tree='tree -I "\.git|\.svn|sandcube"'
  alias diffs='diff -y --suppress-common-lines'

  # grep helpers
  alias grep='terminator::grep::invoke'
  alias egrep='grep -E'
  alias fgrep='grep -F'

  # ag helpers
  alias ag='ag --hidden'

  # vim helpers
  alias vi='vim'
  alias vg='terminator::vim::open::filename_match'
  alias va='terminator::vim::open::content_match'
  alias vd='terminator::vim::open::git_diff'

  # git helpers
  alias g='terminator::git::invoke'
  __git_complete g __git_main

  # ruby helpers
  alias be='bundle exec'

  # beeline helpers
  alias beeline='beeline --color=true'

  terminator::source "${HOME}/.grc/grc.bashrc"
fi
