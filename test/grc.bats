#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/grc.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::grc::__enable__
################################################################################

# bats test_tags=terminator::grc,terminator::grc::__enable__
@test "terminator::grc::__enable__ function-exists" {
  run type -t terminator::grc::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::grc::__disable__
################################################################################

# bats test_tags=terminator::grc,terminator::grc::__disable__
@test "terminator::grc::__disable__ function-exists" {
  run type -t terminator::grc::__disable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::grc::__enable__ / __disable__
################################################################################

# bats test_tags=terminator::grc,terminator::grc::__enable__
@test "terminator::grc::__enable__ when-grc-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::grc::__enable__

  assert_failure
}

# bats test_tags=terminator::grc,terminator::grc::__enable__
@test "terminator::grc::__enable__ when-grc-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::grc::__enable__

  assert_success
}
