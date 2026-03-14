#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/ghostty.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::ghostty::__enable__::os::unsupported
################################################################################

# bats test_tags=terminator::ghostty,terminator::ghostty::__enable__::os::unsupported
@test "terminator::ghostty::__enable__::os::unsupported returns-error" {
  run terminator::ghostty::__enable__::os::unsupported

  assert_failure 1
}

# bats test_tags=terminator::ghostty,terminator::ghostty::__disable__::os::unsupported
@test "terminator::ghostty::__disable__::os::unsupported returns-error" {
  run terminator::ghostty::__disable__::os::unsupported

  assert_failure 1
}

################################################################################
# terminator::ghostty::__enable__::os::linux
################################################################################

# bats test_tags=terminator::ghostty,terminator::ghostty::__enable__::os::linux
@test "terminator::ghostty::__enable__::os::linux is-noop" {
  run terminator::ghostty::__enable__::os::linux

  assert_success
}

# bats test_tags=terminator::ghostty,terminator::ghostty::__disable__::os::linux
@test "terminator::ghostty::__disable__::os::linux is-noop" {
  run terminator::ghostty::__disable__::os::linux

  assert_success
}

################################################################################
# terminator::ghostty::__enable__::os::windows
################################################################################

# bats test_tags=terminator::ghostty,terminator::ghostty::__enable__::os::windows
@test "terminator::ghostty::__enable__::os::windows returns-error" {
  run terminator::ghostty::__enable__::os::windows

  assert_failure 1
}

# bats test_tags=terminator::ghostty,terminator::ghostty::__disable__::os::windows
@test "terminator::ghostty::__disable__::os::windows returns-error" {
  run terminator::ghostty::__disable__::os::windows

  assert_failure 1
}

################################################################################
# terminator::ghostty::__enable__
################################################################################

# bats test_tags=terminator::ghostty,terminator::ghostty::__enable__
@test "terminator::ghostty::__enable__ function-exists" {
  run type -t terminator::ghostty::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::ghostty,terminator::ghostty::__disable__
@test "terminator::ghostty::__disable__ function-exists" {
  run type -t terminator::ghostty::__disable__

  assert_success
  assert_output 'function'
}
