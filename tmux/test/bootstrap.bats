#!/usr/bin/env bats

TMUX_CONFIG_PATH="$HOME/.tmux/config"
source "$HOME/.tmux/src/bootstrap.sh"

load test_helper

@test "tmux::bootstrap::config_path" {
  output=$(tmux::bootstrap::config_path)
  assert_success
  assert_output_regexp "^${TMUX_CONFIG_PATH}$"
}

@test "tmux::bootstrap::config_path 'version'" {
  output=$(tmux::bootstrap::config_path 'version')
  assert_success
  assert_output_regexp "^${TMUX_CONFIG_PATH}/version$"
}

@test "tmux::bootstrap::config_path 'version' '2.9'" {
  output=$(tmux::bootstrap::config_path 'version' '2.9')
  assert_success
  assert_output_regexp "^${TMUX_CONFIG_PATH}/version/2.9$"
}

@test "tmux::bootstrap::version" {
  output=$(tmux::bootstrap::version)
  assert_success
  assert_output_regexp "^[0-9]+\.[0-9]+$"
}
