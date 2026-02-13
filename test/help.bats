#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/help.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::help
################################################################################

# bats test_tags=terminator::help,terminator::help::help
@test "terminator::help command-not-found" {
  run --separate-stderr terminator::help 'this_command_does_not_exist_xyz'

  assert_failure 1
  assert_stderr --partial 'not found'
}

# bats test_tags=terminator::help,terminator::help::command::bash_help
@test "terminator::help::command::bash_help with-builtin" {
  run terminator::help::command::bash_help 'cd'

  assert_success
  assert_output --partial 'cd'
}

# bats test_tags=terminator::help,terminator::help::command::bash_help
@test "terminator::help::command::bash_help with-non-builtin" {
  run terminator::help::command::bash_help 'this_command_does_not_exist_xyz'

  assert_failure
}

################################################################################
# terminator::help::command::help_flag
################################################################################

# bats test_tags=terminator::help,terminator::help::command::help_flag
@test "terminator::help::command::help_flag single-command" {
  run terminator::help::command::help_flag 'bash'

  assert_success
  assert_output --partial 'bash'
}

################################################################################
# terminator::help::command::help_subcommand
################################################################################

# bats test_tags=terminator::help,terminator::help::command::help_subcommand
@test "terminator::help::command::help_subcommand single-command" {
  # Uses 'command help' pattern - git has this
  run terminator::help::command::help_subcommand 'git'

  assert_success
  assert_output --partial 'git'
}

################################################################################
# terminator::help::command::man
################################################################################

# bats test_tags=terminator::help,terminator::help::command::man
@test "terminator::help::command::man with-builtin" {
  # builtins should not be found via man (returns 1 when location is /builtin)
  # In Docker, man may not be available at all, which also returns failure
  run terminator::help::command::man 'cd'

  assert_failure
}

# bats test_tags=terminator::help,terminator::help::command::man
@test "terminator::help::command::man with-nonexistent-command" {
  run terminator::help::command::man 'zzz_nonexistent_command_zzz'

  assert_failure
}
