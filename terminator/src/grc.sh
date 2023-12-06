#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::grc::__enable__() {
  if ! command -v grc > /dev/null 2>&1; then
    terminator::log::warning 'grc is not installed'
    return
  fi

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

function terminator::grc::__export__() {
  :
}

function terminator::grc::__recall__() {
  :
}

terminator::__module__::export
