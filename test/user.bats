#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/user.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::user::is_root
################################################################################

# bats test_tags=terminator::user,terminator::user::is_root
@test "terminator::user::is_root non-root" {
  # In Docker the test runner may be non-root (EUID != 0)
  # EUID is readonly so we can't override it - just test the actual state
  if ((EUID == 0)); then
    run terminator::user::is_root
    assert_success
  else
    run terminator::user::is_root
    assert_failure
  fi
}
