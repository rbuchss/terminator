#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"

terminator::source \
  "${HOME}/.terminator/src/ag.sh" \
  "${HOME}/.terminator/src/dotnet.sh" \
  "${HOME}/.terminator/src/git.sh" \
  "${HOME}/.terminator/src/go.sh" \
  "${HOME}/.terminator/src/grep.sh" \
  "${HOME}/.terminator/src/java.sh" \
  "${HOME}/.terminator/src/jenv.sh" \
  "${HOME}/.terminator/src/jetbrains.sh" \
  "${HOME}/.terminator/src/myjournal.sh" \
  "${HOME}/.terminator/src/mysql.sh" \
  "${HOME}/.terminator/src/nodenv.sh" \
  "${HOME}/.terminator/src/pipx.sh" \
  "${HOME}/.terminator/src/postgresql.sh" \
  "${HOME}/.terminator/src/pyenv.sh" \
  "${HOME}/.terminator/src/python.sh" \
  "${HOME}/.terminator/src/rbenv.sh" \
  "${HOME}/.terminator/src/rg.sh" \
  "${HOME}/.terminator/src/ruby.sh" \
  "${HOME}/.terminator/src/rust.sh" \
  "${HOME}/.terminator/src/terraform.sh" \
  "${HOME}/.terminator/src/vagrant.sh" \
  "${HOME}/.terminator/src/vim.sh"

__modules__=(
  terminator::ag
  terminator::dotnet
  terminator::git
  terminator::go
  terminator::grep
  terminator::java
  # jenv uses PROMPT_COMMAND as a hook (_jenv_export_hook) and is slow ~90ms
  # terminator::jenv
  terminator::jetbrains
  terminator::myjournal
  terminator::mysql
  terminator::nodenv
  terminator::pipx
  terminator::postgresql
  terminator::pyenv
  terminator::python
  terminator::rbenv
  terminator::rg
  terminator::ruby
  terminator::rust
  terminator::source
  terminator::terraform
  terminator::vagrant
  terminator::vim
)

terminator::__module__::enable "${__modules__[@]}"
