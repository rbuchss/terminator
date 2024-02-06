#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'terminator/src/tmux/version.sh'

function stub::terminator::tmux::version {
  function terminator::tmux::version {
    echo '2.1'
  }
}

@test "terminator::tmux::version" {
  run terminator::tmux::version
  assert_success
  assert_output --regexp '^[0-9]+\.[0-9]+$'
}

@test "terminator::tmux::version::compare" {
  run terminator::tmux::version::compare
  assert_failure
}

@test "terminator::tmux::version::compare invalid 1.10" {
  run terminator::tmux::version::compare invalid 1.10
  assert_failure
}

@test "terminator::tmux::version::compare less_than 1.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare less_than 1.10
  assert_failure
}

@test "terminator::tmux::version::compare less_than_or_equal 1.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare less_than_or_equal 1.10
  assert_failure
}

@test "terminator::tmux::version::compare equals 1.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare equals 1.10
  assert_failure
}

@test "terminator::tmux::version::compare greater_than 1.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare greater_than 1.10
  assert_success
}

@test "terminator::tmux::version::compare greater_than_or_equal 1.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare greater_than_or_equal 1.10
  assert_success
}

@test "terminator::tmux::version::compare less_than 2.1" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare less_than 2.1
  assert_failure
}

@test "terminator::tmux::version::compare less_than_or_equal 2.1" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare less_than_or_equal 2.1
  assert_success
}

@test "terminator::tmux::version::compare equals 2.1" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare equals 2.1
  assert_success
}

@test "terminator::tmux::version::compare greater_than 2.1" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare greater_than 2.1
  assert_failure
}

@test "terminator::tmux::version::compare greater_than_or_equal 2.1" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare greater_than_or_equal 2.1
  assert_success
}

@test "terminator::tmux::version::compare less_than 2.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare less_than 2.10
  assert_success
}

@test "terminator::tmux::version::compare less_than_or_equal 2.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare less_than_or_equal 2.10
  assert_success
}

@test "terminator::tmux::version::compare equals 2.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare equals 2.10
  assert_failure
}

@test "terminator::tmux::version::compare greater_than 2.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare greater_than 2.10
  assert_failure
}

@test "terminator::tmux::version::compare greater_than_or_equal 2.10" {
  stub::terminator::tmux::version
  run terminator::tmux::version::compare greater_than_or_equal 2.10
  assert_failure
}
