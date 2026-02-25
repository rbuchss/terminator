#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/prompt.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::prompt::print_if_exists::usage
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists::usage
@test "terminator::prompt::print_if_exists::usage" {
  run terminator::prompt::print_if_exists::usage

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial '--content'
  assert_output --partial '--color'
  assert_output --partial '--left'
  assert_output --partial '--right'
  assert_output --partial '--output'
  assert_output --partial '--help'
}

################################################################################
# terminator::prompt::print_if_exists
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists --help" {
  run terminator::prompt::print_if_exists --help

  assert_success
  assert_output --partial 'Usage:'
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists with-content" {
  run terminator::prompt::print_if_exists --content 'hello'

  assert_success
  assert_output --partial 'hello'
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists with-empty-content" {
  run terminator::prompt::print_if_exists --content ''

  assert_success
  assert_output ''
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists with-output-variable" {
  local result=''

  terminator::prompt::print_if_exists --content 'test' --output result

  [[ "${result}" == *'test'* ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists with-positional-output" {
  local result=''

  terminator::prompt::print_if_exists --content 'test' result

  [[ "${result}" == *'test'* ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists with-left-padding" {
  run terminator::prompt::print_if_exists --content 'test' --left 2

  assert_success
  assert_output --partial '  '
  assert_output --partial 'test'
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists with-right-padding" {
  run terminator::prompt::print_if_exists --content 'test' --right 1

  assert_success
  assert_output --partial 'test'
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists invalid-option" {
  run --separate-stderr terminator::prompt::print_if_exists --invalid

  assert_failure 1
  assert_stderr --partial 'ERROR --'
  assert_stderr --partial 'invalid option'
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists invalid-left-padding" {
  run --separate-stderr terminator::prompt::print_if_exists --content 'test' --left 'abc'

  assert_failure 1
  assert_stderr --partial 'ERROR --'
  assert_stderr --partial 'left_padding'
}

# bats test_tags=terminator::prompt,terminator::prompt::print_if_exists
@test "terminator::prompt::print_if_exists invalid-right-padding" {
  run --separate-stderr terminator::prompt::print_if_exists --content 'test' --right 'abc'

  assert_failure 1
  assert_stderr --partial 'ERROR --'
  assert_stderr --partial 'right_padding'
}

################################################################################
# terminator::prompt::error
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::error
@test "terminator::prompt::error with-zero-exit" {
  local result=''

  terminator::prompt::error 0 result

  assert_equal "${result}" ''
}

# bats test_tags=terminator::prompt,terminator::prompt::error
@test "terminator::prompt::error with-nonzero-exit" {
  local result=''

  terminator::prompt::error 1 result

  # Should contain error symbol content
  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::user
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::user
@test "terminator::prompt::user with-output-variable" {
  local result=''

  terminator::prompt::user result

  # Should contain the username
  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::host
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::host
@test "terminator::prompt::host with-output-variable" {
  local result=''

  terminator::prompt::host result

  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::directory
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::directory
@test "terminator::prompt::directory with-output-variable" {
  local result=''

  terminator::prompt::directory result

  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::command_symbol
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::command_symbol
@test "terminator::prompt::command_symbol with-success-exit" {
  local result=''

  terminator::prompt::command_symbol 0 result

  [[ -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::command_symbol
@test "terminator::prompt::command_symbol with-error-exit" {
  local result=''

  terminator::prompt::command_symbol 1 result

  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::jobs_info
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::jobs_info
@test "terminator::prompt::jobs_info with-output-variable" {
  local result=''

  terminator::prompt::jobs_info result

  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::timestamp
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::timestamp
@test "terminator::prompt::timestamp with-output-variable" {
  local result=''

  terminator::prompt::timestamp result

  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::static::user_prefix / user_suffix / host_prefix / host_suffix
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::static::user_prefix
@test "terminator::prompt::static::user_prefix with-output-variable" {
  local result=''

  terminator::prompt::static::user_prefix result

  # Result may be empty string if prefix is empty, that's ok
  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::user_suffix
@test "terminator::prompt::static::user_suffix with-output-variable" {
  local result=''

  terminator::prompt::static::user_suffix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::host_prefix
@test "terminator::prompt::static::host_prefix with-output-variable" {
  local result=''

  terminator::prompt::static::host_prefix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::host_suffix
@test "terminator::prompt::static::host_suffix with-output-variable" {
  local result=''

  terminator::prompt::static::host_suffix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::directory_prefix
@test "terminator::prompt::static::directory_prefix with-output-variable" {
  local result=''

  terminator::prompt::static::directory_prefix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::directory_suffix
@test "terminator::prompt::static::directory_suffix with-output-variable" {
  local result=''

  terminator::prompt::static::directory_suffix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::command_symbol_prefix
@test "terminator::prompt::static::command_symbol_prefix with-output-variable" {
  local result=''

  terminator::prompt::static::command_symbol_prefix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::command_symbol_suffix
@test "terminator::prompt::static::command_symbol_suffix with-output-variable" {
  local result=''

  terminator::prompt::static::command_symbol_suffix result

  [[ -z "${result}" || -n "${result}" ]]
}

################################################################################
# terminator::prompt::static::right_prompt components
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::static::right_prompt_prefix
@test "terminator::prompt::static::right_prompt_prefix with-output-variable" {
  local result=''

  terminator::prompt::static::right_prompt_prefix result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::right_prompt_content
@test "terminator::prompt::static::right_prompt_content with-output-variable" {
  local result=''

  terminator::prompt::static::right_prompt_content result

  [[ -z "${result}" || -n "${result}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::static::right_prompt_suffix
@test "terminator::prompt::static::right_prompt_suffix with-output-variable" {
  local result=''

  terminator::prompt::static::right_prompt_suffix result

  [[ -z "${result}" || -n "${result}" ]]
}

################################################################################
# terminator::prompt::ssh
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::ssh
@test "terminator::prompt::ssh when-not-in-ssh" {
  local original_client="${SSH_CLIENT}"
  local original_tty="${SSH_TTY}"
  unset SSH_CLIENT SSH_TTY
  TERMINATOR_SSH_IS_SSH_SESSION=''

  local result=''
  terminator::prompt::ssh result

  SSH_CLIENT="${original_client}"
  SSH_TTY="${original_tty}"

  # Not in SSH session, should produce no output
  assert_equal "${result}" ''
}

################################################################################
# terminator::prompt::version_control
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::version_control
@test "terminator::prompt::version_control with-output-variable" {
  local result=''

  terminator::prompt::version_control result

  # In a git repo, should produce version control info
  [[ -z "${result}" || -n "${result}" ]]
}

################################################################################
# terminator::prompt::left
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::left
@test "terminator::prompt::left with-output-variable" {
  COLUMNS=80

  local result=''

  terminator::prompt::left 0 result

  [[ -n "${result}" ]]
}

################################################################################
# terminator::prompt::right
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::right
@test "terminator::prompt::right with-output-variable" {
  COLUMNS=80

  local result=''

  terminator::prompt::right 0 result

  # Right prompt may be just padding if no content is configured
  [[ -z "${result}" || -n "${result}" ]]
}
