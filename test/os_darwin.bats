#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/os/darwin.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::os::darwin::finder::show_hidden_files
################################################################################

# bats test_tags=terminator::os,terminator::os::darwin,terminator::os::darwin::finder::show_hidden_files
@test "terminator::os::darwin::finder::show_hidden_files function-exists" {
  run type -t terminator::os::darwin::finder::show_hidden_files

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::os,terminator::os::darwin,terminator::os::darwin::finder::hide_hidden_files
@test "terminator::os::darwin::finder::hide_hidden_files function-exists" {
  run type -t terminator::os::darwin::finder::hide_hidden_files

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::os,terminator::os::darwin,terminator::os::darwin::finder::set_show_all_files
@test "terminator::os::darwin::finder::set_show_all_files function-exists" {
  run type -t terminator::os::darwin::finder::set_show_all_files

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::os,terminator::os::darwin,terminator::os::darwin::screencapture::set_location
@test "terminator::os::darwin::screencapture::set_location function-exists" {
  run type -t terminator::os::darwin::screencapture::set_location

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::os::darwin::__enable__
################################################################################

# bats test_tags=terminator::os,terminator::os::darwin,terminator::os::darwin::__enable__
@test "terminator::os::darwin::__enable__ sets-TERMINATOR_SCREENSHOTS_DIR" {
  unset TERMINATOR_SCREENSHOTS_DIR

  terminator::os::darwin::__enable__

  [[ -n "${TERMINATOR_SCREENSHOTS_DIR}" ]]
  [[ "${TERMINATOR_SCREENSHOTS_DIR}" == *'Screenshots'* ]]
}

# bats test_tags=terminator::os,terminator::os::darwin,terminator::os::darwin::__enable__
@test "terminator::os::darwin::__enable__ preserves-existing-TERMINATOR_SCREENSHOTS_DIR" {
  TERMINATOR_SCREENSHOTS_DIR='/custom/path'

  terminator::os::darwin::__enable__

  [[ "${TERMINATOR_SCREENSHOTS_DIR}" == '/custom/path' ]]
}
