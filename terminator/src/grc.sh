#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::grc::__enable__ {
  terminator::command::exists -v grc || return

  alias colourify='command grc -es --colour=auto'
  alias blkid='colourify blkid'
  alias configure='colourify ./configure'
  alias df='colourify df'
  alias diff='colourify diff'
  alias docker='colourify docker'
  alias docker-machine='colourify docker-machine'
  alias du='colourify du'
  alias env='colourify env'
  alias free='colourify free'
  alias fdisk='colourify fdisk'
  alias findmnt='colourify findmnt'
  # alias make='colourify make'
  alias gcc='colourify gcc'
  alias g++='colourify g++'
  alias id='colourify id'
  alias ip='colourify ip'
  alias iptables='colourify iptables'
  alias as='colourify as'
  alias gas='colourify gas'
  alias ld='colourify ld'
  # alias ls='colourify ls'
  alias lsof='colourify lsof'
  alias lsblk='colourify lsblk'
  alias lspci='colourify lspci'
  alias netstat='colourify netstat'
  alias ping='colourify ping'
  alias traceroute='colourify traceroute'
  alias traceroute6='colourify traceroute6'
  alias head='colourify head'
  alias tail='colourify tail'
  alias dig='colourify dig'
  alias mount='colourify mount'
  alias ps='colourify ps'
  alias mtr='colourify mtr'
  alias semanage='colourify semanage'
  alias getsebool='colourify getsebool'
  alias ifconfig='colourify ifconfig'
  alias mvn='colourify mvn'
}

function terminator::grc::__disable__ {
  unalias colourify
  unalias blkid
  unalias configure
  unalias df
  unalias diff
  unalias docker
  unalias docker-machine
  unalias du
  unalias env
  unalias free
  unalias fdisk
  unalias findmnt
  # unalias make
  unalias gcc
  unalias g++
  unalias id
  unalias ip
  unalias iptables
  unalias as
  unalias gas
  unalias ld
  # unalias ls
  unalias lsof
  unalias lsblk
  unalias lspci
  unalias netstat
  unalias ping
  unalias traceroute
  unalias traceroute6
  unalias head
  unalias tail
  unalias dig
  unalias mount
  unalias ps
  unalias mtr
  unalias semanage
  unalias getsebool
  unalias ifconfig
  unalias mvn
}

function terminator::grc::__export__ {
  :
}

function terminator::grc::__recall__ {
  :
}

terminator::__module__::export
