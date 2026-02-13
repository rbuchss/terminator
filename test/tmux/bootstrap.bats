#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'terminator/src/tmux/bootstrap.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tmux::bootstrap::messages::path
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::bootstrap,terminator::tmux::bootstrap::messages::path
@test "terminator::tmux::bootstrap::messages::path" {
  run terminator::tmux::bootstrap::messages::path

  assert_success
  # Should return a path with 'conf' instead of 'log'
  assert_output --partial 'conf'
}

# bats test_tags=terminator::tmux,terminator::tmux::bootstrap,terminator::tmux::bootstrap::messages::path
@test "terminator::tmux::bootstrap::messages::path direct-call" {
  local result
  result="$(terminator::tmux::bootstrap::messages::path)"

  [[ "${result}" == *'conf'* ]]
}

################################################################################
# terminator::tmux::bootstrap::build_messages
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::bootstrap,terminator::tmux::bootstrap::build_messages
@test "terminator::tmux::bootstrap::build_messages with-empty-log" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  # Create an empty log file where tmux::logger::path points
  local log_path
  log_path="$(terminator::tmux::logger::path)"

  # Override TMUX_LOG_DIR to use temp dir
  local original_log_dir="${TMUX_LOG_DIR}"
  TMUX_LOG_DIR="${temp_dir}"

  # Create the log path structure in temp dir
  local actual_log_path="${temp_dir}/tmux-bootstrap.log"
  : >"${actual_log_path}"

  # If the log file is empty, build_messages should return 0
  run terminator::tmux::bootstrap::build_messages

  TMUX_LOG_DIR="${original_log_dir}"

  assert_success

  rm -rf "${temp_dir}"
}
