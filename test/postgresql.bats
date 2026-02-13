#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/postgresql.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::postgresql::list_config
################################################################################

# bats test_tags=terminator::postgresql,terminator::postgresql::list_config
@test "terminator::postgresql::list_config function-exists" {
  run type -t terminator::postgresql::list_config

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::postgresql::edit_config
################################################################################

# bats test_tags=terminator::postgresql,terminator::postgresql::edit_config
@test "terminator::postgresql::edit_config function-exists" {
  run type -t terminator::postgresql::edit_config

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::postgresql::clear_pid
################################################################################

# bats test_tags=terminator::postgresql,terminator::postgresql::clear_pid
@test "terminator::postgresql::clear_pid function-exists" {
  run type -t terminator::postgresql::clear_pid

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::postgresql::__enable__
################################################################################

# bats test_tags=terminator::postgresql,terminator::postgresql::__enable__
@test "terminator::postgresql::__enable__ when-psql-not-available" {
  if command -v psql >/dev/null 2>&1; then
    skip 'psql is installed — cannot test absence'
  fi

  run terminator::postgresql::__enable__

  # Returns early with failure when psql not found
  assert_failure
}
