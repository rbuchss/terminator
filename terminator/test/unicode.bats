#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/unicode.sh'

@test "terminator::unicode::code 0xE0A0" {
  run terminator::unicode::code 0xE0A0
  assert_success
  assert_output ''
}

@test "terminator::unicode::code 0xE0A0 result" {
  local result
  # `run` seems to keep result from being set ...
  terminator::unicode::code 0xE0A0 result
  assert_success
  assert_equal '' "${result}"
}

@test "terminator::unicode::code 0xE0A0 result -> no output" {
  local result
  # `run` seems to keep result from being set ...
  run terminator::unicode::code 0xE0A0 result
  assert_success
  assert_no_output_exists
}
