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
