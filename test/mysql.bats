#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/mysql.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::mysql::find_column
################################################################################

# bats test_tags=terminator::mysql,terminator::mysql::find_column
@test "terminator::mysql::find_column with-no-args" {
  run --separate-stderr terminator::mysql::find_column

  assert_failure 65
  assert_stderr --partial 'ERROR: invalid # of args'
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::mysql,terminator::mysql::find_column
@test "terminator::mysql::find_column with-one-arg" {
  run --separate-stderr terminator::mysql::find_column 'mydb'

  assert_failure 65
  assert_stderr --partial 'ERROR: invalid # of args'
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::mysql,terminator::mysql::find_column
@test "terminator::mysql::find_column with-three-args" {
  run --separate-stderr terminator::mysql::find_column 'mydb' 'col' 'extra'

  assert_failure 65
  assert_stderr --partial 'ERROR: invalid # of args'
  assert_stderr --partial 'Usage:'
}
