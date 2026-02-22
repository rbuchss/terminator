#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/jetbrains.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::jetbrains::__enable__::os::unsupported
################################################################################

# bats test_tags=terminator::jetbrains,terminator::jetbrains::__enable__::os::unsupported
@test "terminator::jetbrains::__enable__::os::unsupported returns-error" {
  run terminator::jetbrains::__enable__::os::unsupported

  assert_failure 1
}

# bats test_tags=terminator::jetbrains,terminator::jetbrains::__disable__::os::unsupported
@test "terminator::jetbrains::__disable__::os::unsupported returns-error" {
  run terminator::jetbrains::__disable__::os::unsupported

  assert_failure 1
}

################################################################################
# terminator::jetbrains::__enable__::os::linux
################################################################################

# bats test_tags=terminator::jetbrains,terminator::jetbrains::__enable__::os::linux
@test "terminator::jetbrains::__enable__::os::linux runs-without-error" {
  run terminator::jetbrains::__enable__::os::linux

  assert_success
}

# bats test_tags=terminator::jetbrains,terminator::jetbrains::__disable__::os::linux
@test "terminator::jetbrains::__disable__::os::linux runs-without-error" {
  run terminator::jetbrains::__disable__::os::linux

  assert_success
}

################################################################################
# terminator::jetbrains::__enable__
################################################################################

# bats test_tags=terminator::jetbrains,terminator::jetbrains::__enable__
@test "terminator::jetbrains::__enable__ function-exists" {
  run type -t terminator::jetbrains::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::jetbrains,terminator::jetbrains::__disable__
@test "terminator::jetbrains::__disable__ function-exists" {
  run type -t terminator::jetbrains::__disable__

  assert_success
  assert_output 'function'
}
