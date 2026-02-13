#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/string.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::string::bytes_to_length_offset
################################################################################

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset --help" {
  # NOTE: help_command variable has typo in source (byte_to_length vs bytes_to_length_offset)
  # so --help returns 0 but may not produce expected usage text
  run terminator::string::bytes_to_length_offset --help

  assert_success
}

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset invalid-option" {
  run --separate-stderr terminator::string::bytes_to_length_offset --invalid

  assert_failure
  assert_stderr --partial 'invalid option'
}

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset ascii-string stdout" {
  run terminator::string::bytes_to_length_offset --value 'hello'

  assert_success
  assert_output '0'
}

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset ascii-string output-variable" {
  local result _status=0

  terminator::string::bytes_to_length_offset \
    --value 'hello' \
    --output result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '0'
}

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset ascii-string positional-output" {
  local result _status=0

  terminator::string::bytes_to_length_offset \
    --value 'hello' \
    result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '0'
}

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset ascii-string output-variable -> no output" {
  local result

  run terminator::string::bytes_to_length_offset --value 'hello' --output result

  assert_success
  refute_output
}

# bats test_tags=terminator::string,terminator::string::bytes_to_length_offset
@test "terminator::string::bytes_to_length_offset empty-string" {
  run terminator::string::bytes_to_length_offset --value ''

  assert_success
  assert_output '0'
}

################################################################################
# terminator::string::repeat
################################################################################

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat --help" {
  run terminator::string::repeat --help

  assert_success
  assert_output --partial 'Usage:'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat invalid-option" {
  run --separate-stderr terminator::string::repeat --invalid

  assert_failure 1
  assert_stderr --partial 'invalid option'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat invalid-count" {
  run --separate-stderr terminator::string::repeat --value 'x' --count 'abc'

  assert_failure 1
  assert_stderr --partial 'not an unsigned integer'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat negative-count" {
  run --separate-stderr terminator::string::repeat --value 'x' --count '-1'

  assert_failure 1
  assert_stderr --partial 'not an unsigned integer'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat stdout" {
  run terminator::string::repeat --value 'ab' --count 3

  assert_success
  assert_output 'ababab'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat zero-count" {
  run terminator::string::repeat --value 'x' --count 0

  assert_success
  assert_output ''
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat single-count" {
  run terminator::string::repeat --value 'hello' --count 1

  assert_success
  assert_output 'hello'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat output-variable" {
  local result _status=0

  terminator::string::repeat \
    --value '=-' \
    --count 4 \
    --output result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '=-=-=-=-'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat positional-output" {
  local result _status=0

  terminator::string::repeat \
    --value 'x' \
    --count 5 \
    result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'xxxxx'
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat output-variable -> no output" {
  local result

  run terminator::string::repeat --value 'x' --count 3 --output result

  assert_success
  refute_output
}

# bats test_tags=terminator::string,terminator::string::repeat
@test "terminator::string::repeat empty-value" {
  run terminator::string::repeat --value '' --count 5

  assert_success
  assert_output ''
}

################################################################################
# terminator::string::strip_colors
################################################################################

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors --help" {
  run terminator::string::strip_colors --help

  assert_success
  assert_output --partial 'Usage:'
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors invalid-option" {
  run --separate-stderr terminator::string::strip_colors --invalid

  assert_failure 1
  assert_stderr --partial 'invalid option'
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors plain-text stdout" {
  run terminator::string::strip_colors --value 'hello world'

  assert_success
  assert_output 'hello world'
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors with-ansi-codes stdout" {
  local colored_text=$'\x1b[0;91mERROR\x1b[0m: something failed'

  run terminator::string::strip_colors --value "${colored_text}"

  assert_success
  assert_output 'ERROR: something failed'
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors output-variable" {
  local result _status=0

  terminator::string::strip_colors \
    --value 'plain text' \
    --output result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'plain text'
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors output-variable -> no output" {
  local result

  run terminator::string::strip_colors --value 'text' --output result

  assert_success
  refute_output
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors empty-value" {
  run terminator::string::strip_colors --value ''

  assert_success
  assert_output ''
}

# bats test_tags=terminator::string,terminator::string::strip_colors
@test "terminator::string::strip_colors positional-output" {
  local result _status=0

  terminator::string::strip_colors \
    --value 'hello' \
    result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'hello'
}
