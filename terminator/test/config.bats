#!/usr/bin/env bats

load test_helper

source "$(repo_root)/terminator/src/config.sh"

@test "terminator::config::path" {
  run terminator::config::path
  assert_success
  assert_output "${HOME}/.terminator/config"
}

@test "terminator::config::path .bashrc" {
  run terminator::config::path '.bashrc'
  assert_success
  assert_output "${HOME}/.terminator/config/.bashrc"
}

@test "terminator::config::path os darwin.sh" {
  run terminator::config::path 'os' 'darwin.sh'
  assert_success
  assert_output "${HOME}/.terminator/config/os/darwin.sh"
}
