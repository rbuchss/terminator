#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/ruby.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::ruby::bundle_search
################################################################################

# bats test_tags=terminator::ruby,terminator::ruby::bundle_search
@test "terminator::ruby::bundle_search function-exists" {
  run type -t terminator::ruby::bundle_search

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::ruby::rails::diff
################################################################################

# bats test_tags=terminator::ruby,terminator::ruby::rails::diff
@test "terminator::ruby::rails::diff function-exists" {
  run type -t terminator::ruby::rails::diff

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::ruby::rails::create_clean_database
################################################################################

# bats test_tags=terminator::ruby,terminator::ruby::rails::create_clean_database
@test "terminator::ruby::rails::create_clean_database function-exists" {
  run type -t terminator::ruby::rails::create_clean_database

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::ruby::__enable__
################################################################################

# bats test_tags=terminator::ruby,terminator::ruby::__enable__
@test "terminator::ruby::__enable__ when-no-ruby-or-rbenv" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::any_exist { return 1; }

  run terminator::ruby::__enable__

  assert_failure
}

# bats test_tags=terminator::ruby,terminator::ruby::__enable__
@test "terminator::ruby::__enable__ when-ruby-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::any_exist { return 0; }

  run terminator::ruby::__enable__

  assert_success
}
