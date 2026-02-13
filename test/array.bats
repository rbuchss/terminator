#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/array.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::array::contains
################################################################################

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-element-present" {
  run terminator::array::contains 'foo' 'bar' 'foo' 'baz'

  assert_success
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-element-not-present" {
  run terminator::array::contains 'missing' 'bar' 'foo' 'baz'

  assert_failure
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-empty-array" {
  run terminator::array::contains 'foo'

  assert_failure
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-single-element-match" {
  run terminator::array::contains 'only' 'only'

  assert_success
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-single-element-no-match" {
  run terminator::array::contains 'missing' 'only'

  assert_failure
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-first-element" {
  run terminator::array::contains 'first' 'first' 'second' 'third'

  assert_success
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-last-element" {
  run terminator::array::contains 'last' 'first' 'second' 'last'

  assert_success
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-special-characters" {
  run terminator::array::contains 'hello world' 'foo' 'hello world' 'bar'

  assert_success
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-empty-string-element" {
  run terminator::array::contains '' 'foo' '' 'bar'

  assert_success
}

# bats test_tags=terminator::array,terminator::array::contains
@test "terminator::array::contains with-empty-string-not-in-array" {
  run terminator::array::contains '' 'foo' 'bar'

  assert_failure
}
