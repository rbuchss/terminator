#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/git.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::git::invoke
################################################################################

# bats test_tags=terminator::git,terminator::git::invoke
@test "terminator::git::invoke runs-git" {
  run terminator::git::invoke --version

  assert_success
  assert_output --partial 'git version'
}

# bats test_tags=terminator::git,terminator::git::invoke
@test "terminator::git::invoke passes-arguments" {
  run terminator::git::invoke status --short

  assert_success
}

# bats test_tags=terminator::git,terminator::git::invoke
@test "terminator::git::invoke help" {
  run terminator::git::invoke help

  assert_success
  assert_output --partial 'git'
}
