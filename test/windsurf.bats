#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/windsurf.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::windsurf::__enable__::os::unsupported
################################################################################

# bats test_tags=terminator::windsurf,terminator::windsurf::__enable__::os::unsupported
@test "terminator::windsurf::__enable__::os::unsupported returns-error" {
  run terminator::windsurf::__enable__::os::unsupported

  assert_failure 1
}

# bats test_tags=terminator::windsurf,terminator::windsurf::__disable__::os::unsupported
@test "terminator::windsurf::__disable__::os::unsupported returns-error" {
  run terminator::windsurf::__disable__::os::unsupported

  assert_failure 1
}

################################################################################
# terminator::windsurf::__enable__::os::linux
################################################################################

# bats test_tags=terminator::windsurf,terminator::windsurf::__enable__::os::linux
@test "terminator::windsurf::__enable__::os::linux returns-error" {
  run terminator::windsurf::__enable__::os::linux

  assert_failure 1
}

# bats test_tags=terminator::windsurf,terminator::windsurf::__disable__::os::linux
@test "terminator::windsurf::__disable__::os::linux returns-error" {
  run terminator::windsurf::__disable__::os::linux

  assert_failure 1
}

################################################################################
# terminator::windsurf::__enable__::os::windows
################################################################################

# bats test_tags=terminator::windsurf,terminator::windsurf::__enable__::os::windows
@test "terminator::windsurf::__enable__::os::windows returns-error" {
  run terminator::windsurf::__enable__::os::windows

  assert_failure 1
}

# bats test_tags=terminator::windsurf,terminator::windsurf::__disable__::os::windows
@test "terminator::windsurf::__disable__::os::windows returns-error" {
  run terminator::windsurf::__disable__::os::windows

  assert_failure 1
}

################################################################################
# terminator::windsurf::__enable__
################################################################################

# bats test_tags=terminator::windsurf,terminator::windsurf::__enable__
@test "terminator::windsurf::__enable__ function-exists" {
  run type -t terminator::windsurf::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::windsurf,terminator::windsurf::__disable__
@test "terminator::windsurf::__disable__ function-exists" {
  run type -t terminator::windsurf::__disable__

  assert_success
  assert_output 'function'
}
