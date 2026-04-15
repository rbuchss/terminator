#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/awake.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::awake::invoke
################################################################################

# bats test_tags=terminator::awake,terminator::awake::invoke
@test "terminator::awake::invoke function-exists" {
  run type -t terminator::awake::invoke

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::awake,terminator::awake::invoke
@test "terminator::awake::invoke --help prints-usage" {
  run terminator::awake::invoke --help

  assert_success
  assert_output --partial 'Usage: awake'
}

# bats test_tags=terminator::awake,terminator::awake::invoke
@test "terminator::awake::invoke rejects-non-numeric-hours" {
  run terminator::awake::invoke abc

  assert_failure
  assert_output --partial "invalid hours: 'abc'"
}

# bats test_tags=terminator::awake,terminator::awake::invoke
@test "terminator::awake::invoke rejects-zero-hours" {
  run terminator::awake::invoke 0

  assert_failure
  assert_output --partial "invalid hours: '0'"
}

################################################################################
# terminator::awake::invoke::os::darwin
################################################################################

# bats test_tags=terminator::awake,terminator::awake::invoke::os::darwin
@test "terminator::awake::invoke::os::darwin function-exists" {
  run type -t terminator::awake::invoke::os::darwin

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::awake::invoke::os::linux
################################################################################

# bats test_tags=terminator::awake,terminator::awake::invoke::os::linux
@test "terminator::awake::invoke::os::linux function-exists" {
  run type -t terminator::awake::invoke::os::linux

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::awake::invoke::os::windows
################################################################################

# bats test_tags=terminator::awake,terminator::awake::invoke::os::windows
@test "terminator::awake::invoke::os::windows function-exists" {
  run type -t terminator::awake::invoke::os::windows

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::awake::invoke::os::unsupported
################################################################################

# bats test_tags=terminator::awake,terminator::awake::invoke::os::unsupported
@test "terminator::awake::invoke::os::unsupported function-exists" {
  run type -t terminator::awake::invoke::os::unsupported

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::awake,terminator::awake::invoke::os::unsupported
@test "terminator::awake::invoke::os::unsupported returns-failure" {
  run terminator::awake::invoke::os::unsupported

  assert_failure
  assert_output --partial "not supported"
}

################################################################################
# terminator::awake::invoke::usage
################################################################################

# bats test_tags=terminator::awake,terminator::awake::invoke::usage
@test "terminator::awake::invoke::usage function-exists" {
  run type -t terminator::awake::invoke::usage

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::awake::completion
################################################################################

# bats test_tags=terminator::awake,terminator::awake::completion
@test "terminator::awake::completion function-exists" {
  run type -t terminator::awake::completion

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::awake,terminator::awake::completion
@test "terminator::awake::completion suggests-all-for-empty-word" {
  COMP_WORDS=('awake' '')
  COMP_CWORD=1

  terminator::awake::completion

  # All defaults should appear
  [[ " ${COMPREPLY[*]} " == *' 0.5 '* ]]
  [[ " ${COMPREPLY[*]} " == *' 2 '* ]]
  [[ " ${COMPREPLY[*]} " == *' 24 '* ]]
}

# bats test_tags=terminator::awake,terminator::awake::completion
@test "terminator::awake::completion filters-by-prefix" {
  COMP_WORDS=('awake' '1')
  COMP_CWORD=1

  terminator::awake::completion

  # '1' should match only '1' and '12'
  [[ " ${COMPREPLY[*]} " == *' 1 '* ]]
  [[ " ${COMPREPLY[*]} " == *' 12 '* ]]
  [[ " ${COMPREPLY[*]} " != *' 2 '* ]]
  [[ " ${COMPREPLY[*]} " != *' 24 '* ]]
}

################################################################################
# terminator::awake::__enable__
################################################################################

# bats test_tags=terminator::awake,terminator::awake::__enable__
@test "terminator::awake::__enable__ function-exists" {
  run type -t terminator::awake::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::awake::__enable__::os::darwin
################################################################################

# bats test_tags=terminator::awake,terminator::awake::__enable__::os::darwin
@test "terminator::awake::__enable__::os::darwin when-caffeinate-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::awake::__enable__::os::darwin

  assert_failure
}

# bats test_tags=terminator::awake,terminator::awake::__enable__::os::darwin
@test "terminator::awake::__enable__::os::darwin when-caffeinate-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::awake::__enable__::os::darwin

  assert_success
}

################################################################################
# terminator::awake::__enable__::os::linux
################################################################################

# bats test_tags=terminator::awake,terminator::awake::__enable__::os::linux
@test "terminator::awake::__enable__::os::linux when-systemd-inhibit-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::awake::__enable__::os::linux

  assert_failure
}

# bats test_tags=terminator::awake,terminator::awake::__enable__::os::linux
@test "terminator::awake::__enable__::os::linux when-systemd-inhibit-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::awake::__enable__::os::linux

  assert_success
}

################################################################################
# terminator::awake::__enable__::os::unsupported
################################################################################

# bats test_tags=terminator::awake,terminator::awake::__enable__::os::unsupported
@test "terminator::awake::__enable__::os::unsupported returns-failure" {
  run terminator::awake::__enable__::os::unsupported

  assert_failure
  assert_output --partial "not supported"
}
