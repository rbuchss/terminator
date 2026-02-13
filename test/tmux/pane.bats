#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'terminator/src/tmux/pane.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tmux::pane::session_window_pane_pattern
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::session_window_pane_pattern
@test "terminator::tmux::pane::session_window_pane_pattern" {
  run terminator::tmux::pane::session_window_pane_pattern

  assert_success
  assert_output 'session-#{session_name}.window-#{window_name}.pane-#{pane_index}'
}

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::session_window_pane_pattern
@test "terminator::tmux::pane::session_window_pane_pattern direct-call" {
  local result
  result="$(terminator::tmux::pane::session_window_pane_pattern)"

  assert_equal "${result}" 'session-#{session_name}.window-#{window_name}.pane-#{pane_index}'
}

################################################################################
# terminator::tmux::pane::default_log_name
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::default_log_name
@test "terminator::tmux::pane::default_log_name" {
  run terminator::tmux::pane::default_log_name 'tmux-pipe'

  assert_success
  # Output should contain the log type and end with .log
  assert_output --partial 'tmux-pipe'
  assert_output --partial '.log'
  assert_output --partial 'session-#{session_name}'
}

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::default_log_name
@test "terminator::tmux::pane::default_log_name direct-call" {
  local result
  result="$(terminator::tmux::pane::default_log_name 'tmux-save')"

  [[ "${result}" == *'tmux-save'* ]]
  [[ "${result}" == *'.log'* ]]
}

################################################################################
# terminator::tmux::pane::default_log_path
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::default_log_path
@test "terminator::tmux::pane::default_log_path" {
  run terminator::tmux::pane::default_log_path 'tmux-pipe'

  assert_success
  assert_output --partial 'tmux-pipe'
  assert_output --partial '.log'
}

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::default_log_path
@test "terminator::tmux::pane::default_log_path with-custom-directory" {
  run terminator::tmux::pane::default_log_path 'tmux-pipe' '/custom/logs'

  assert_success
  assert_output --partial '/custom/logs/'
  assert_output --partial 'tmux-pipe'
}

# bats test_tags=terminator::tmux,terminator::tmux::pane,terminator::tmux::pane::default_log_path
@test "terminator::tmux::pane::default_log_path direct-call" {
  local result
  result="$(terminator::tmux::pane::default_log_path 'tmux-save' '/tmp')"

  [[ "${result}" == /tmp/* ]]
  [[ "${result}" == *'tmux-save'* ]]
  [[ "${result}" == *'.log' ]]
}
