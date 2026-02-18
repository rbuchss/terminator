#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/vagrant.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::vagrant::scp
################################################################################

# bats test_tags=terminator::vagrant,terminator::vagrant::scp
@test "terminator::vagrant::scp function-exists" {
  run type -t terminator::vagrant::scp

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::vagrant::__enable__
################################################################################

# bats test_tags=terminator::vagrant,terminator::vagrant::__enable__
@test "terminator::vagrant::__enable__ when-vagrant-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::vagrant::__enable__

  assert_failure
}

# bats test_tags=terminator::vagrant,terminator::vagrant::__enable__
@test "terminator::vagrant::__enable__ when-vagrant-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::vagrant::__enable__

  assert_success
}
