#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/network.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::network::expand_url
################################################################################

# bats test_tags=terminator::network,terminator::network::expand_url
@test "terminator::network::expand_url function-exists" {
  run type -t terminator::network::expand_url

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::network::external_ip
################################################################################

# bats test_tags=terminator::network,terminator::network::external_ip
@test "terminator::network::external_ip function-exists" {
  run type -t terminator::network::external_ip

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::network::__enable__
################################################################################

# bats test_tags=terminator::network,terminator::network::__enable__
@test "terminator::network::__enable__ when-curl-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::network::__enable__

  assert_failure
}

# bats test_tags=terminator::network,terminator::network::__enable__
@test "terminator::network::__enable__ when-curl-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::network::__enable__

  assert_success
}
