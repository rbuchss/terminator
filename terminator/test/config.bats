#!/usr/bin/env bats

load test_helper

source "$(repo_root)/terminator/src/config.sh"

@test "terminator::config::path" {
  run terminator::config::path
  assert_success
  assert_output "${TERMINATOR_CONFIG_DIR}"
}

@test "terminator::config::path '.bashrc' '${HOME}'" {
  run terminator::config::path ".bashrc" "${HOME}"
  assert_success
  assert_output "${HOME}/.bashrc"
}

@test "terminator::config::path '${HOME}/.bashrc'" {
  run terminator::config::path "${HOME}/.bashrc"
  assert_success
  assert_output "${HOME}/.bashrc"
}

@test "terminator::config::path '~/.bashrc'" {
  run terminator::config::path "~/.bashrc"
  assert_success
  assert_output "~/.bashrc"
}

@test "terminator::config::path os/darwin.sh" {
  run terminator::config::path 'os/darwin.sh'
  assert_success
  assert_output "${TERMINATOR_CONFIG_DIR}/os/darwin.sh"
}

@test "terminator::config::path os/darwin.sh config_dir_override" {
  run terminator::config::path 'os/darwin.sh' 'config_dir_override'
  assert_success
  assert_output "config_dir_override/os/darwin.sh"
}
