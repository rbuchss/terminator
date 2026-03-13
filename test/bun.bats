#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/bun.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::bun::__enable__
################################################################################

# bats test_tags=terminator::bun,terminator::bun::__enable__
@test "terminator::bun::__enable__ function-exists" {
  run type -t terminator::bun::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::bun,terminator::bun::__enable__
@test "terminator::bun::__enable__ when-bun-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::bun::__enable__

  assert_failure
}

# bats test_tags=terminator::bun,terminator::bun::__enable__
@test "terminator::bun::__enable__ when-bun-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::bun::__enable__

  assert_success
}

################################################################################
# terminator::bun::__disable__
################################################################################

# bats test_tags=terminator::bun,terminator::bun::__disable__
@test "terminator::bun::__disable__ function-exists" {
  run type -t terminator::bun::__disable__

  assert_success
  assert_output 'function'
}
