#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/number.sh'

@test "terminator::number::compare" {
  run terminator::number::compare
  assert_failure 4
}

@test "terminator::number::compare 0" {
  run terminator::number::compare 0
  assert_failure 4
}

@test "terminator::number::compare 1 1" {
  run terminator::number::compare 1 1
  assert_success
}

@test "terminator::number::compare -1 1" {
  run terminator::number::compare -1 1
  assert_failure 2
}

@test "terminator::number::compare -2 -1" {
  run terminator::number::compare -2 -1
  assert_failure 2
}

@test "terminator::number::compare 1 1.1" {
  run terminator::number::compare 1 1.1
  assert_failure 2
}

@test "terminator::number::compare 1.1 1.10" {
  run terminator::number::compare 1.1 1.10
  assert_success
}

@test "terminator::number::compare 1.1 1.0" {
  run terminator::number::compare 1.1 1.0
  assert_failure 1
}

@test "terminator::number::compare 5.65 3.14e-22" {
  run terminator::number::compare 5.65 3.14e-22
  assert_failure 1
}

@test "terminator::number::compare 5.65e-23 3.14e-22" {
  run terminator::number::compare 5.65e-23 3.14e-22
  assert_failure 2
}

@test "terminator::number::compare 3.145678 3.145679" {
  run terminator::number::compare 3.145678 3.145679
  assert_failure 2
}

@test "terminator::number::compare 0xDEADBEEF 0xDEADBEF0" {
  run terminator::number::compare 0xDEADBEEF 0xDEADBEF0
  assert_failure 2
}

@test "terminator::number::compare 0xDEADBEEF 0xDEADBEEE" {
  run terminator::number::compare 0xDEADBEEF 0xDEADBEEE
  assert_failure 1
}
