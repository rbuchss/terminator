#!/bin/bash

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/.terminator/src/source.sh"

  terminator::source \
    "${HOME}/.terminator/tools/grc/grc.bashrc" \
    "${HOME}/.terminator/src/file.sh" \
    "${HOME}/.terminator/src/network.sh" \
    "${HOME}/.terminator/src/process.sh" \
    "${HOME}/.terminator/src/utility.sh"

  # bash helpers
  alias clr='clear'
  alias df='df -kTh'
  alias du='du -kh'
  alias hideme='history -d $((HISTCMD-1)) &&'
  alias hack='terminator::utility::hack'
  alias history_stats='terminator::utility::history_stats'
  alias reverse_endianness='terminator::utility::reverse_endianness'

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
  alias tree='tree -I "\.git|\.svn|sandcube|node_modules"'
  alias diffs='diff -y --suppress-common-lines'
  alias extract='terminator::file::extract'
  alias mktar='terminator::file::mktar'
  alias mktgz='terminator::file::mktgz'
  alias mktbz='terminator::file::mktbz'
  alias swap='terminator::file::swap'
  alias nuke_spaces='terminator::file::nuke_spaces'
  alias find_exec='terminator::file::find_exec'
  alias dirsize_big='terminator::file::dirsize_big'
  alias dirsize='terminator::file::dirsize'
  alias mkcd='terminator::file::mkcd'

  # process helpers
  alias kill_match='terminator::process::kill'

  # network helpers
  alias expand_url='terminator::network::expand_url'
fi
