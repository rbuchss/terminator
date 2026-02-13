#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/color.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::color::code
################################################################################

# bats test_tags=terminator::color,terminator::color::code
@test "terminator::color::code stdout" {
  local expected
  printf -v expected '\[\x1b[%s\]' '0;91m'

  run terminator::color::code '0;91m'

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::color,terminator::color::code
@test "terminator::color::code output-variable" {
  local result expected _status=0

  terminator::color::code '0;91m' result \
    || _status="$?"

  printf -v expected '\[\x1b[%s\]' '0;91m'

  assert_equal "${_status}" 0
  assert_equal "${result}" "${expected}"
}

# bats test_tags=terminator::color,terminator::color::code
@test "terminator::color::code output-variable -> no output" {
  local result

  run terminator::color::code '0;91m' result

  assert_success
  refute_output
}

# bats test_tags=terminator::color,terminator::color::code
@test "terminator::color::code invalid-args" {
  run --separate-stderr terminator::color::code

  assert_success
  refute_output
  assert_stderr
}

# bats test_tags=terminator::color,terminator::color::code
@test "terminator::color::code too-many-args" {
  run --separate-stderr terminator::color::code 'a' 'b' 'c'

  assert_success
  refute_output
  assert_stderr
}

################################################################################
# terminator::color::code_bare
################################################################################

# bats test_tags=terminator::color,terminator::color::code_bare
@test "terminator::color::code_bare stdout" {
  local expected
  printf -v expected '\x1b[%s' '38;5;69m'

  run terminator::color::code_bare '38;5;69m'

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::color,terminator::color::code_bare
@test "terminator::color::code_bare output-variable" {
  local result expected _status=0

  terminator::color::code_bare '38;5;69m' result \
    || _status="$?"

  printf -v expected '\x1b[%s' '38;5;69m'

  assert_equal "${_status}" 0
  assert_equal "${result}" "${expected}"
}

# bats test_tags=terminator::color,terminator::color::code_bare
@test "terminator::color::code_bare output-variable -> no output" {
  local result

  run terminator::color::code_bare '38;5;69m' result

  assert_success
  refute_output
}

# bats test_tags=terminator::color,terminator::color::code_bare
@test "terminator::color::code_bare invalid-args" {
  run --separate-stderr terminator::color::code_bare

  assert_success
  refute_output
  assert_stderr
}

################################################################################
# terminator::color::off
################################################################################

# bats test_tags=terminator::color,terminator::color::off
@test "terminator::color::off stdout" {
  local expected
  printf -v expected '\[\x1b[%s\]' '0m'

  run terminator::color::off

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::color,terminator::color::off
@test "terminator::color::off output-variable" {
  local result expected _status=0

  terminator::color::off result \
    || _status="$?"

  printf -v expected '\[\x1b[%s\]' '0m'

  assert_equal "${_status}" 0
  assert_equal "${result}" "${expected}"
}

# bats test_tags=terminator::color,terminator::color::off
@test "terminator::color::off output-variable -> no output" {
  local result

  run terminator::color::off result

  assert_success
  refute_output
}

################################################################################
# terminator::color::off_bare
################################################################################

# bats test_tags=terminator::color,terminator::color::off_bare
@test "terminator::color::off_bare stdout" {
  local expected
  printf -v expected '\x1b[%s' '0m'

  # shellcheck disable=SC2119
  run terminator::color::off_bare

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::color,terminator::color::off_bare
@test "terminator::color::off_bare output-variable" {
  local result expected _status=0

  terminator::color::off_bare result \
    || _status="$?"

  printf -v expected '\x1b[%s' '0m'

  assert_equal "${_status}" 0
  assert_equal "${result}" "${expected}"
}

################################################################################
# terminator::color::highlight_demo
################################################################################

# bats test_tags=terminator::color,terminator::color::highlight_demo
@test "terminator::color::highlight_demo" {
  run terminator::color::highlight_demo

  assert_success
  assert_output
}

################################################################################
# terminator::color::demo
################################################################################

# bats test_tags=terminator::color,terminator::color::demo
@test "terminator::color::demo" {
  run terminator::color::demo

  assert_success
  assert_output
}
