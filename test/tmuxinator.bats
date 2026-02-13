#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/tmuxinator.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::tmuxinator::completion::add_alias
################################################################################

# bats test_tags=terminator::tmuxinator,terminator::tmuxinator::completion::add_alias
@test "terminator::tmuxinator::completion::add_alias registers-completion" {
  run terminator::tmuxinator::completion::add_alias 'test_alias_name'

  assert_success
}

################################################################################
# terminator::tmuxinator::completion::remove_alias
################################################################################

# bats test_tags=terminator::tmuxinator,terminator::tmuxinator::completion::remove_alias
@test "terminator::tmuxinator::completion::remove_alias removes-completion" {
  # First add, then remove
  terminator::tmuxinator::completion::add_alias 'test_remove_alias'

  run terminator::tmuxinator::completion::remove_alias 'test_remove_alias'

  assert_success
}

################################################################################
# terminator::tmuxinator
################################################################################

# bats test_tags=terminator::tmuxinator,terminator::tmuxinator::invoke
@test "terminator::tmuxinator::invoke function-exists" {
  run type -t terminator::tmuxinator::invoke

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::tmuxinator,terminator::tmuxinator::completion
@test "terminator::tmuxinator::completion function-exists" {
  run type -t terminator::tmuxinator::completion

  assert_success
  assert_output 'function'
}
