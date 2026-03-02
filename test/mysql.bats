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
  assert_stderr --partial 'ERROR --'
  assert_stderr --partial 'invalid # of args'
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::mysql,terminator::mysql::find_column
@test "terminator::mysql::find_column with-one-arg" {
  run --separate-stderr terminator::mysql::find_column 'mydb'

  assert_failure 65
  assert_stderr --partial 'ERROR --'
  assert_stderr --partial 'invalid # of args'
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::mysql,terminator::mysql::find_column
@test "terminator::mysql::find_column with-three-args" {
  run --separate-stderr terminator::mysql::find_column 'mydb' 'col' 'extra'

  assert_failure 65
  assert_stderr --partial 'ERROR --'
  assert_stderr --partial 'invalid # of args'
  assert_stderr --partial 'Usage:'
}

################################################################################
# terminator::mysql::__enable__
################################################################################

# bats test_tags=terminator::mysql,terminator::mysql::__enable__
@test "terminator::mysql::__enable__ when-mysql-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::mysql::__enable__

  assert_failure
}

# bats test_tags=terminator::mysql,terminator::mysql::__enable__
@test "terminator::mysql::__enable__ when-mysql-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::mysql::__enable__

  assert_success
}
