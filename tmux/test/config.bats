#!/usr/bin/env bats

load test_helper

TMUX_CONFIG_PATH="$HOME/.tmux/config"
source "$(repo_root)/tmux/src/config.sh"

@test "tmux::config::path" {
  run tmux::config::path
  assert_success
  assert_output_regexp "^${TMUX_CONFIG_PATH}$"
}

@test "tmux::config::version::path" {
  run tmux::config::version::path
  assert_success
  assert_output_regexp "^${TMUX_CONFIG_PATH}/version$"
}

@test "tmux::config::version::path '2.9'" {
  run tmux::config::version::path '2.9'
  assert_success
  assert_output_regexp "^${TMUX_CONFIG_PATH}/version/2.9$"
}
