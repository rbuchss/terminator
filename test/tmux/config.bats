#!/usr/bin/env bats

load ../test_helper

TMUX_CONFIG_PATH="${HOME}/.config/tmux"
setup_with_coverage 'terminator/src/tmux/config.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tmux::config::path
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::path
@test "terminator::tmux::config::path" {
  run terminator::tmux::config::path
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}$"
}

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::path
@test "terminator::tmux::config::path single-segment" {
  run terminator::tmux::config::path 'styles'
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/styles$"
}

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::path
@test "terminator::tmux::config::path multiple-segments" {
  run terminator::tmux::config::path 'version' '3.0' 'styles.conf'
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/version/3.0/styles.conf$"
}

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::path
@test "terminator::tmux::config::path with-custom-TMUX_CONFIG_PATH" {
  local original_path="${TMUX_CONFIG_PATH}"
  TMUX_CONFIG_PATH='/custom/tmux'

  run terminator::tmux::config::path 'config.conf'

  TMUX_CONFIG_PATH="${original_path}"

  assert_success
  assert_output '/custom/tmux/config.conf'
}

################################################################################
# terminator::tmux::config::version::path
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::version::path
@test "terminator::tmux::config::version::path" {
  run terminator::tmux::config::version::path
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/version$"
}

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::version::path
@test "terminator::tmux::config::version::path '2.9'" {
  run terminator::tmux::config::version::path '2.9'
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/version/2.9$"
}

# bats test_tags=terminator::tmux,terminator::tmux::config,terminator::tmux::config::version::path
@test "terminator::tmux::config::version::path '3.0' 'styles.conf'" {
  run terminator::tmux::config::version::path '3.0' 'styles.conf'
  assert_success
  assert_output --regexp "^${TMUX_CONFIG_PATH}/version/3.0/styles.conf$"
}
