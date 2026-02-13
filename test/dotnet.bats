#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/dotnet.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::dotnet::complete
################################################################################

# bats test_tags=terminator::dotnet,terminator::dotnet::complete
@test "terminator::dotnet::complete function-exists" {
  run type -t terminator::dotnet::complete

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::dotnet::__enable__
################################################################################

# bats test_tags=terminator::dotnet,terminator::dotnet::__enable__
@test "terminator::dotnet::__enable__ function-exists" {
  run type -t terminator::dotnet::__enable__

  assert_success
  assert_output 'function'
}
