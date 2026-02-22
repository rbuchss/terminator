#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/dircolors.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::dircolors::__enable__
################################################################################

# bats test_tags=terminator::dircolors,terminator::dircolors::__enable__
@test "terminator::dircolors::__enable__ function-exists" {
  run type -t terminator::dircolors::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::dircolors::__disable__
################################################################################

# bats test_tags=terminator::dircolors,terminator::dircolors::__disable__
@test "terminator::dircolors::__disable__ function-exists" {
  run type -t terminator::dircolors::__disable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::dircolors,terminator::dircolors::__disable__
@test "terminator::dircolors::__disable__ unsets-LS_COLORS" {
  LS_COLORS='test'

  terminator::dircolors::__disable__

  [[ -z "${LS_COLORS+x}" ]]
}
