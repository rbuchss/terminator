#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/unicode.sh'

@test "terminator::unicode::code 0xE0A0" {
  run terminator::unicode::code 0xE0A0

  assert_success
  assert_output ''
}

@test "terminator::unicode::code 0xE0A0 result" {
  local result _status=0

  terminator::unicode::code 0xE0A0 result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" ''
}

@test "terminator::unicode::code 0xE0A0 result -> no output" {
  local result

  run terminator::unicode::code 0xE0A0 result

  assert_success
  refute_output
}
