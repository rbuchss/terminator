#!/bin/bash

function terminator::rust::bootstrap() {
  terminator::path::prepend "$HOME/.cargo/bin"
  # NOTE: to enable rustup completion use the following command:
  #   rustup completions bash > ${system_completion_path}

  # NOTE: This enables cargo completion and must be loaded after
  # cargo is added to the path
  source $(rustc --print sysroot)/etc/bash_completion.d/cargo
}
