#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/tmux.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tmux::invoke
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke function-exists" {
  run type -t terminator::tmux::invoke

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::tmux::__enable__
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::__enable__
@test "terminator::tmux::__enable__ function-exists" {
  run type -t terminator::tmux::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::tmux::__disable__
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::__disable__
@test "terminator::tmux::__disable__ function-exists" {
  run type -t terminator::tmux::__disable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::tmux::invoke
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke with-args-passes-through" {
  run terminator::tmux::invoke -V

  assert_success
  assert_output --partial 'tmux'
}
