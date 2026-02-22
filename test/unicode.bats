#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/unicode.sh'

################################################################################
# terminator::unicode::code
################################################################################

# bats test_tags=terminator::unicode,terminator::unicode::code
@test "terminator::unicode::code 0xE0A0" {
  run terminator::unicode::code 0xE0A0

  assert_success
  assert_output $'\xee\x82\xa0'
}

# bats test_tags=terminator::unicode,terminator::unicode::code
@test "terminator::unicode::code 0xE0A0 result" {
  local result _status=0

  terminator::unicode::code 0xE0A0 result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" $'\xee\x82\xa0'
}

# bats test_tags=terminator::unicode,terminator::unicode::code
@test "terminator::unicode::code 0xE0A0 result -> no output" {
  local result

  run terminator::unicode::code 0xE0A0 result

  assert_success
  refute_output
}
