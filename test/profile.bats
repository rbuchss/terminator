#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/profile.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::profile::os::unsupported
################################################################################

# bats test_tags=terminator::profile,terminator::profile::os::unsupported
@test "terminator::profile::os::unsupported returns-error" {
  run terminator::profile::os::unsupported

  assert_failure 1
}

# bats test_tags=terminator::profile,terminator::profile::os::unsupported
@test "terminator::profile::os::unsupported direct-call" {
  local exit_status=0

  terminator::profile::os::unsupported 2>/dev/null || exit_status=$?

  ((exit_status == 1))
}

################################################################################
# terminator::profile
################################################################################

# bats test_tags=terminator::profile,terminator::profile::load
@test "terminator::profile::load function-exists" {
  run type -t terminator::profile::load

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::profile,terminator::profile::os::darwin
@test "terminator::profile::os::darwin function-exists" {
  run type -t terminator::profile::os::darwin

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::profile,terminator::profile::os::linux
@test "terminator::profile::os::linux function-exists" {
  run type -t terminator::profile::os::linux

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::profile,terminator::profile::os::windows
@test "terminator::profile::os::windows function-exists" {
  run type -t terminator::profile::os::windows

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::profile,terminator::profile::os::unsupported
@test "terminator::profile::os::unsupported function-exists" {
  run type -t terminator::profile::os::unsupported

  assert_success
  assert_output 'function'
}
