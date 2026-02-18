#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/process.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::process::kill
################################################################################

# bats test_tags=terminator::process,terminator::process::kill
@test "terminator::process::kill with-no-args" {
  run --separate-stderr terminator::process::kill

  assert_failure 1
  assert_stderr --partial 'ERROR:'
  assert_stderr --partial 'invalid number of arguments'
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::process,terminator::process::kill
@test "terminator::process::kill with-too-many-args" {
  run --separate-stderr terminator::process::kill '-TERM' 'pattern' 'extra'

  assert_failure 1
  assert_stderr --partial 'ERROR:'
  assert_stderr --partial 'invalid number of arguments'
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::process,terminator::process::kill
@test "terminator::process::kill with-no-matching-processes" {
  run terminator::process::kill 'zzz_nonexistent_pattern_zzz'

  assert_success
  assert_output --partial 'Found 0 processes'
}

################################################################################
# terminator::process::__enable__
################################################################################

# bats test_tags=terminator::process,terminator::process::__enable__
@test "terminator::process::__enable__ sets-alias" {
  terminator::process::__enable__

  alias kill_match
}

################################################################################
# terminator::process::__disable__
################################################################################

# bats test_tags=terminator::process,terminator::process::__disable__
@test "terminator::process::__disable__ removes-alias" {
  terminator::process::__enable__
  terminator::process::__disable__

  local exit_code=0
  alias kill_match 2>/dev/null || exit_code=$?
  ((exit_code != 0))
}
