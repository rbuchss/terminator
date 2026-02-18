#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/tree.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tree::__enable__
################################################################################

# bats test_tags=terminator::tree,terminator::tree::__enable__
@test "terminator::tree::__enable__ function-exists" {
  run type -t terminator::tree::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::tree::__disable__
################################################################################

# bats test_tags=terminator::tree,terminator::tree::__disable__
@test "terminator::tree::__disable__ function-exists" {
  run type -t terminator::tree::__disable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::tree::__enable__ / __disable__
################################################################################

# bats test_tags=terminator::tree,terminator::tree::__enable__
@test "terminator::tree::__enable__ when-tree-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::tree::__enable__

  assert_failure
}

# bats test_tags=terminator::tree,terminator::tree::__enable__
@test "terminator::tree::__enable__ when-tree-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::tree::__enable__

  assert_success
}
