#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/__module__.sh"
source "${HOME}/.terminator/src/source.sh"

terminator::source \
  "${HOME}/.terminator/src/ag.sh" \
  "${HOME}/.terminator/src/byte.sh" \
  "${HOME}/.terminator/src/claude.sh" \
  "${HOME}/.terminator/src/config.sh" \
  "${HOME}/.terminator/src/diff.sh" \
  "${HOME}/.terminator/src/dotnet.sh" \
  "${HOME}/.terminator/src/file.sh" \
  "${HOME}/.terminator/src/gcloud.sh" \
  "${HOME}/.terminator/src/ghostty.sh" \
  "${HOME}/.terminator/src/git.sh" \
  "${HOME}/.terminator/src/go.sh" \
  "${HOME}/.terminator/src/grc.sh" \
  "${HOME}/.terminator/src/grep.sh" \
  "${HOME}/.terminator/src/history.sh" \
  "${HOME}/.terminator/src/java.sh" \
  "${HOME}/.terminator/src/jenv.sh" \
  "${HOME}/.terminator/src/jetbrains.sh" \
  "${HOME}/.terminator/src/kubectl.sh" \
  "${HOME}/.terminator/src/less.sh" \
  "${HOME}/.terminator/src/ls.sh" \
  "${HOME}/.terminator/src/myjournal.sh" \
  "${HOME}/.terminator/src/mysql.sh" \
  "${HOME}/.terminator/src/network.sh" \
  "${HOME}/.terminator/src/nodenv.sh" \
  "${HOME}/.terminator/src/pipx.sh" \
  "${HOME}/.terminator/src/postgresql.sh" \
  "${HOME}/.terminator/src/process.sh" \
  "${HOME}/.terminator/src/pyenv.sh" \
  "${HOME}/.terminator/src/python.sh" \
  "${HOME}/.terminator/src/rbenv.sh" \
  "${HOME}/.terminator/src/rg.sh" \
  "${HOME}/.terminator/src/ruby.sh" \
  "${HOME}/.terminator/src/rust.sh" \
  "${HOME}/.terminator/src/ssh.sh" \
  "${HOME}/.terminator/src/terraform.sh" \
  "${HOME}/.terminator/src/tmux.sh" \
  "${HOME}/.terminator/src/tmuxinator.sh" \
  "${HOME}/.terminator/src/tree.sh" \
  "${HOME}/.terminator/src/vagrant.sh" \
  "${HOME}/.terminator/src/vim.sh" \
  "${HOME}/.terminator/src/windsurf.sh"

__modules__=(
  terminator::ag
  terminator::byte
  terminator::claude
  terminator::config
  terminator::diff
  terminator::dotnet
  terminator::file
  terminator::gcloud
  terminator::ghostty
  terminator::git
  terminator::go
  terminator::grep
  terminator::history
  terminator::java
  # jenv uses PROMPT_COMMAND as a hook (_jenv_export_hook) and is slow ~90ms
  # terminator::jenv
  terminator::jetbrains
  terminator::kubectl
  terminator::less
  terminator::ls
  terminator::myjournal
  terminator::mysql
  terminator::network
  terminator::nodenv
  terminator::pipx
  terminator::postgresql
  terminator::process
  terminator::pyenv
  terminator::python
  terminator::rbenv
  terminator::rg
  terminator::ruby
  terminator::rust
  terminator::source
  terminator::ssh
  terminator::terraform
  terminator::tmux
  terminator::tmuxinator
  terminator::tree
  terminator::vagrant
  terminator::vim
  terminator::windsurf
)

terminator::__module__::enable "${__modules__[@]}"
