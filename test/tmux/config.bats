#!/usr/bin/env bats

load ../test_helper

TMUX_CONFIG_PATH="${HOME}/.config/tmux"
setup_with_coverage 'terminator/src/tmux/config.sh'

@test "terminator::tmux::config::path" {
  run terminator::tmux::config::path
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}$"
}

@test "terminator::tmux::config::version::path" {
  run terminator::tmux::config::version::path
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/version$"
}

@test "terminator::tmux::config::version::path '2.9'" {
  run terminator::tmux::config::version::path '2.9'
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/version/2.9$"
}
