#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'terminator/src/tmux/logger.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tmux::logger::path
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::path
@test "terminator::tmux::logger::path" {
  run terminator::tmux::logger::path

  assert_success
  assert_output --regexp '^/tmp/tmux-session\.[0-9]+\.log$'
}

################################################################################
# terminator::tmux::logger::wrapper
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::wrapper
@test "terminator::tmux::logger::wrapper no-args" {
  run --separate-stderr terminator::tmux::logger::wrapper

  assert_failure 1
  assert_stderr --partial 'invalid number of arguments'
}

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::wrapper
@test "terminator::tmux::logger::wrapper with-callback" {
  run --separate-stderr terminator::tmux::logger::wrapper \
    terminator::logger::info 'test message'

  assert_success
}

################################################################################
# terminator::tmux::logger::console::info
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::console::info
@test "terminator::tmux::logger::console::info" {
  run --separate-stderr terminator::tmux::logger::console::info 'test info message'

  assert_success
  assert_stderr --partial 'test info message'
}

################################################################################
# terminator::tmux::logger::console::warning
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::console::warning
@test "terminator::tmux::logger::console::warning" {
  run --separate-stderr terminator::tmux::logger::console::warning 'test warning message'

  assert_success
  assert_stderr --partial 'test warning message'
}

################################################################################
# terminator::tmux::logger::console::error
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::console::error
@test "terminator::tmux::logger::console::error" {
  run --separate-stderr terminator::tmux::logger::console::error 'test error message'

  assert_success
  assert_stderr --partial 'test error message'
}

################################################################################
# terminator::tmux::logger::console::fatal
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::console::fatal
@test "terminator::tmux::logger::console::fatal" {
  run --separate-stderr terminator::tmux::logger::console::fatal 'test fatal message'

  assert_success
  assert_stderr --partial 'test fatal message'
}

################################################################################
# terminator::tmux::logger::console::debug
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::console::debug
@test "terminator::tmux::logger::console::debug with-debug-level" {
  local original_level="${TMUX_LOG_LEVEL}"
  TMUX_LOG_LEVEL='debug'

  run --separate-stderr terminator::tmux::logger::console::debug 'test debug message'

  TMUX_LOG_LEVEL="${original_level}"

  assert_success
  assert_stderr --partial 'test debug message'
}

################################################################################
# terminator::tmux::logger::info
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::info
@test "terminator::tmux::logger::info" {
  run --separate-stderr terminator::tmux::logger::info 'combined info message'

  assert_success
  assert_stderr --partial 'combined info message'
}

################################################################################
# terminator::tmux::logger::warning
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::warning
@test "terminator::tmux::logger::warning" {
  run --separate-stderr terminator::tmux::logger::warning 'combined warning message'

  assert_success
  assert_stderr --partial 'combined warning message'
}

################################################################################
# terminator::tmux::logger::error
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::error
@test "terminator::tmux::logger::error" {
  run --separate-stderr terminator::tmux::logger::error 'combined error message'

  assert_success
  assert_stderr --partial 'combined error message'
}

################################################################################
# terminator::tmux::logger::fatal
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::fatal
@test "terminator::tmux::logger::fatal" {
  run --separate-stderr terminator::tmux::logger::fatal 'combined fatal message'

  assert_success
  assert_stderr --partial 'combined fatal message'
}

################################################################################
# terminator::tmux::logger::debug
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::debug
@test "terminator::tmux::logger::debug with-debug-level" {
  local original_level="${TMUX_LOG_LEVEL}"
  TMUX_LOG_LEVEL='debug'

  run --separate-stderr terminator::tmux::logger::debug 'combined debug message'

  TMUX_LOG_LEVEL="${original_level}"

  assert_success
  assert_stderr --partial 'combined debug message'
}

################################################################################
# terminator::tmux::logger::file
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::file::info
@test "terminator::tmux::logger::file::info writes-to-file" {
  run terminator::tmux::logger::file::info 'file info message'

  assert_success
}

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::file::warning
@test "terminator::tmux::logger::file::warning writes-to-file" {
  run terminator::tmux::logger::file::warning 'file warning message'

  assert_success
}

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::file::error
@test "terminator::tmux::logger::file::error writes-to-file" {
  run terminator::tmux::logger::file::error 'file error message'

  assert_success
}

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::file::fatal
@test "terminator::tmux::logger::file::fatal writes-to-file" {
  run terminator::tmux::logger::file::fatal 'file fatal message'

  assert_success
}

# bats test_tags=terminator::tmux,terminator::tmux::logger,terminator::tmux::logger::file::debug
@test "terminator::tmux::logger::file::debug with-debug-level" {
  local original_level="${TMUX_LOG_LEVEL}"
  TMUX_LOG_LEVEL='debug'

  run terminator::tmux::logger::file::debug 'file debug message'

  TMUX_LOG_LEVEL="${original_level}"

  assert_success
}
