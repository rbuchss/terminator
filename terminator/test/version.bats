#!/usr/bin/env bats

load test_helper

source "$(repo_root)/terminator/src/version.sh"

@test "terminator::version::compare 1 1" {
  run terminator::version::compare 1 1
  assert_exit_status 0
}

@test "terminator::version::compare 2.1 2.2" {
  run terminator::version::compare 2.1 2.2
  assert_exit_status 2
}

@test "terminator::version::compare 3.0.4.10 3.0.4.2" {
  run terminator::version::compare 3.0.4.10 3.0.4.2
  assert_exit_status 1
}

@test "terminator::version::compare 4.08 4.08.01" {
  run terminator::version::compare 4.08 4.08.01
  assert_exit_status 2
}

@test "terminator::version::compare 3.2.1.9.8144 3.2" {
  run terminator::version::compare 3.2.1.9.8144 3.2
  assert_exit_status 1
}

@test "terminator::version::compare 3.2 3.2.1.9.8144" {
  run terminator::version::compare 3.2 3.2.1.9.8144
  assert_exit_status 2
}

@test "terminator::version::compare 1.2 2.1" {
  run terminator::version::compare 1.2 2.1
  assert_exit_status 2
}

@test "terminator::version::compare 2.1 1.2" {
  run terminator::version::compare 2.1 1.2
  assert_exit_status 1
}

@test "terminator::version::compare 5.6.7 5.6.7" {
  run terminator::version::compare 5.6.7 5.6.7
  assert_exit_status 0
}

@test "terminator::version::compare 1.01.1 1.1.1" {
  run terminator::version::compare 1.01.1 1.1.1
  assert_exit_status 0
}

@test "terminator::version::compare 1.1.1 1.01.1" {
  run terminator::version::compare 1.1.1 1.01.1
  assert_exit_status 0
}

@test "terminator::version::compare 1 1.0" {
  run terminator::version::compare 1 1.0
  assert_exit_status 0
}

@test "terminator::version::compare 1.0 1" {
  run terminator::version::compare 1.0 1
  assert_exit_status 0
}

@test "terminator::version::compare 1.0.2.0 1.0.2" {
  run terminator::version::compare 1.0.2.0 1.0.2
  assert_exit_status 0
}

@test "terminator::version::compare 1..0 1.0" {
  run terminator::version::compare 1..0 1.0
  assert_exit_status 0
}

@test "terminator::version::compare 1.0 1..0" {
  run terminator::version::compare 1.0 1..0
  assert_exit_status 0
}
