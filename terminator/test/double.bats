#!/usr/bin/env bats

load test_helper

source "$(repo_root)/terminator/src/double.sh"

@test "terminator::double::compare" {
  run terminator::double::compare
  assert_exit_status 4
}

@test "terminator::double::compare 0" {
  run terminator::double::compare 0
  assert_exit_status 4
}

@test "terminator::double::compare 1 1" {
  run terminator::double::compare 1 1
  assert_exit_status 0
}

@test "terminator::double::compare -1 1" {
  run terminator::double::compare -1 1
  assert_exit_status 2
}

@test "terminator::double::compare -2 -1" {
  run terminator::double::compare -2 -1
  assert_exit_status 2
}

@test "terminator::double::compare 1 1.1" {
  run terminator::double::compare 1 1.1
  assert_exit_status 2
}

@test "terminator::double::compare 1.1 1.10" {
  run terminator::double::compare 1.1 1.10
  assert_exit_status 0
}

@test "terminator::double::compare 1.1 1.0" {
  run terminator::double::compare 1.1 1.0
  assert_exit_status 1
}

@test "terminator::double::compare 5.65 3.14e-22" {
  run terminator::double::compare 5.65 3.14e-22
  assert_exit_status 1
}

@test "terminator::double::compare 5.65e-23 3.14e-22" {
  run terminator::double::compare 5.65e-23 3.14e-22
  assert_exit_status 2
}

@test "terminator::double::compare 3.145678 3.145679" {
  run terminator::double::compare 3.145678 3.145679
  assert_exit_status 2
}

@test "terminator::double::compare 0xDEADBEEF 0xDEADBEF0" {
  run terminator::double::compare 0xDEADBEEF 0xDEADBEF0
  assert_exit_status 2
}

@test "terminator::double::compare 0xDEADBEEF 0xDEADBEEE" {
  run terminator::double::compare 0xDEADBEEF 0xDEADBEEE
  assert_exit_status 1
}
