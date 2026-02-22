#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/diff.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::diff::__enable__
################################################################################

# bats test_tags=terminator::diff,terminator::diff::__enable__
@test "terminator::diff::__enable__ function-exists" {
  run type -t terminator::diff::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::diff::__disable__
################################################################################

# bats test_tags=terminator::diff,terminator::diff::__disable__
@test "terminator::diff::__disable__ function-exists" {
  run type -t terminator::diff::__disable__

  assert_success
  assert_output 'function'
}
