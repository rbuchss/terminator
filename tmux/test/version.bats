#!/usr/bin/env bats

load test_helper

setup_with_coverage 'tmux/src/version.sh'

function stub::tmux::version() {
  function tmux::version() {
    echo '2.1'
  }
}

@test "tmux::version" {
  run tmux::version
  assert_success
  assert_output_regexp '^[0-9]+\.[0-9]+$'
}

@test "tmux::version::compare" {
  run tmux::version::compare
  assert_failure
}

@test "tmux::version::compare invalid 1.10" {
  run tmux::version::compare invalid 1.10
  assert_failure
}

@test "tmux::version::compare less_than 1.10" {
  stub::tmux::version
  run tmux::version::compare less_than 1.10
  assert_failure
}

@test "tmux::version::compare less_than_or_equal 1.10" {
  stub::tmux::version
  run tmux::version::compare less_than_or_equal 1.10
  assert_failure
}

@test "tmux::version::compare equals 1.10" {
  stub::tmux::version
  run tmux::version::compare equals 1.10
  assert_failure
}

@test "tmux::version::compare greater_than 1.10" {
  stub::tmux::version
  run tmux::version::compare greater_than 1.10
  assert_success
}

@test "tmux::version::compare greater_than_or_equal 1.10" {
  stub::tmux::version
  run tmux::version::compare greater_than_or_equal 1.10
  assert_success
}

@test "tmux::version::compare less_than 2.1" {
  stub::tmux::version
  run tmux::version::compare less_than 2.1
  assert_failure
}

@test "tmux::version::compare less_than_or_equal 2.1" {
  stub::tmux::version
  run tmux::version::compare less_than_or_equal 2.1
  assert_success
}

@test "tmux::version::compare equals 2.1" {
  stub::tmux::version
  run tmux::version::compare equals 2.1
  assert_success
}

@test "tmux::version::compare greater_than 2.1" {
  stub::tmux::version
  run tmux::version::compare greater_than 2.1
  assert_failure
}

@test "tmux::version::compare greater_than_or_equal 2.1" {
  stub::tmux::version
  run tmux::version::compare greater_than_or_equal 2.1
  assert_success
}

@test "tmux::version::compare less_than 2.10" {
  stub::tmux::version
  run tmux::version::compare less_than 2.10
  assert_success
}

@test "tmux::version::compare less_than_or_equal 2.10" {
  stub::tmux::version
  run tmux::version::compare less_than_or_equal 2.10
  assert_success
}

@test "tmux::version::compare equals 2.10" {
  stub::tmux::version
  run tmux::version::compare equals 2.10
  assert_failure
}

@test "tmux::version::compare greater_than 2.10" {
  stub::tmux::version
  run tmux::version::compare greater_than 2.10
  assert_failure
}

@test "tmux::version::compare greater_than_or_equal 2.10" {
  stub::tmux::version
  run tmux::version::compare greater_than_or_equal 2.10
  assert_failure
}
