#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/go.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::go::__enable__
################################################################################

# bats test_tags=terminator::go,terminator::go::__enable__
@test "terminator::go::__enable__ function-exists" {
  run type -t terminator::go::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::go,terminator::go::__enable__
@test "terminator::go::__enable__ when-go-not-available" {
  if command -v go >/dev/null 2>&1; then
    skip 'go is installed — cannot test absence'
  fi

  run terminator::go::__enable__

  # Returns early with failure when go not found
  assert_failure
}

################################################################################
# terminator::go::__disable__
################################################################################

# bats test_tags=terminator::go,terminator::go::__disable__
@test "terminator::go::__disable__ function-exists" {
  run type -t terminator::go::__disable__

  assert_success
  assert_output 'function'
}
