#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/terraform.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::terraform::__enable__
################################################################################

# bats test_tags=terminator::terraform,terminator::terraform::__enable__
@test "terminator::terraform::__enable__ function-exists" {
  run type -t terminator::terraform::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::terraform,terminator::terraform::__enable__
@test "terminator::terraform::__enable__ when-terraform-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::terraform::__enable__

  assert_failure
}

# bats test_tags=terminator::terraform,terminator::terraform::__enable__
@test "terminator::terraform::__enable__ when-terraform-available" {
  # Mock command::exists but let homebrew::package::is_installed run normally
  # (it will return false since brew is not installed, skipping completion setup)
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::terraform::__enable__

  assert_success
}
