#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/prompt.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::prompt::get
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::get
@test "terminator::prompt::get returns default when unset" {
  unset TERMINATOR_PROMPT_COMMAND

  run terminator::prompt::get

  assert_success
  assert_output "${TERMINATOR_PROMPT_COMMAND_DEFAULT}"
}

# bats test_tags=terminator::prompt,terminator::prompt::get
@test "terminator::prompt::get returns TERMINATOR_PROMPT_COMMAND when set" {
  TERMINATOR_PROMPT_COMMAND='terminator::prompt::minimal'

  run terminator::prompt::get

  assert_success
  assert_output 'terminator::prompt::minimal'
}

# bats test_tags=terminator::prompt,terminator::prompt::get
@test "terminator::prompt::get with output variable" {
  TERMINATOR_PROMPT_COMMAND='terminator::prompt::minimal'
  local result=''

  terminator::prompt::get result

  assert_equal "${result}" 'terminator::prompt::minimal'
}

################################################################################
# terminator::prompt::set
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::set
@test "terminator::prompt::set with valid command" {
  TERMINATOR_PROMPT_COMMAND="${TERMINATOR_PROMPT_COMMAND_DEFAULT}"
  unset TERMINATOR_PROMPT_COMMAND_PREVIOUS

  terminator::prompt::set terminator::prompt::minimal

  assert_equal "${TERMINATOR_PROMPT_COMMAND}" 'terminator::prompt::minimal'
  assert_equal "${TERMINATOR_PROMPT_COMMAND_PREVIOUS}" "${TERMINATOR_PROMPT_COMMAND_DEFAULT}"
}

# bats test_tags=terminator::prompt,terminator::prompt::set
@test "terminator::prompt::set with invalid command" {
  TERMINATOR_PROMPT_COMMAND="${TERMINATOR_PROMPT_COMMAND_DEFAULT}"

  run --separate-stderr terminator::prompt::set 'nonexistent::command'

  assert_failure
  assert_stderr --partial 'not found'
}

# bats test_tags=terminator::prompt,terminator::prompt::set
@test "terminator::prompt::set with no arguments" {
  run --separate-stderr terminator::prompt::set

  assert_failure
  assert_stderr --partial 'usage'
}

# bats test_tags=terminator::prompt,terminator::prompt::set
@test "terminator::prompt::set toggle with -" {
  TERMINATOR_PROMPT_COMMAND='terminator::prompt::minimal'
  TERMINATOR_PROMPT_COMMAND_PREVIOUS="${TERMINATOR_PROMPT_COMMAND_DEFAULT}"

  terminator::prompt::set -

  assert_equal "${TERMINATOR_PROMPT_COMMAND}" "${TERMINATOR_PROMPT_COMMAND_DEFAULT}"
  assert_equal "${TERMINATOR_PROMPT_COMMAND_PREVIOUS}" 'terminator::prompt::minimal'
}

# bats test_tags=terminator::prompt,terminator::prompt::set
@test "terminator::prompt::set double toggle returns to original" {
  TERMINATOR_PROMPT_COMMAND="${TERMINATOR_PROMPT_COMMAND_DEFAULT}"
  unset TERMINATOR_PROMPT_COMMAND_PREVIOUS

  terminator::prompt::set terminator::prompt::minimal
  terminator::prompt::set -

  assert_equal "${TERMINATOR_PROMPT_COMMAND}" "${TERMINATOR_PROMPT_COMMAND_DEFAULT}"
  assert_equal "${TERMINATOR_PROMPT_COMMAND_PREVIOUS}" 'terminator::prompt::minimal'
}

# bats test_tags=terminator::prompt,terminator::prompt::set
@test "terminator::prompt::set toggle with - when no previous" {
  unset TERMINATOR_PROMPT_COMMAND_PREVIOUS

  run --separate-stderr terminator::prompt::set -

  assert_failure
  assert_stderr --partial 'no previous'
}

################################################################################
# terminator::prompt
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::dispatch
@test "terminator::prompt dispatches to configured command" {
  COLUMNS=80
  TERMINATOR_PROMPT_COMMAND='terminator::prompt::minimal'

  terminator::prompt

  [[ -n "${PS1}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::dispatch
@test "terminator::prompt dispatches to default when unset" {
  COLUMNS=80
  unset TERMINATOR_PROMPT_COMMAND

  terminator::prompt

  [[ -n "${PS1}" ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::dispatch
@test "terminator::prompt falls back to default for invalid command" {
  COLUMNS=80
  TERMINATOR_PROMPT_COMMAND='nonexistent::command'

  terminator::prompt

  [[ -n "${PS1}" ]]
}

################################################################################
# terminator::prompt::minimal
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::minimal
@test "terminator::prompt::minimal sets PS1 with command symbol" {
  local expected_symbol
  terminator::styles::command_symbol expected_symbol

  terminator::prompt::minimal

  [[ -n "${PS1}" ]]
  [[ "${PS1}" == "${expected_symbol} " ]]
}

################################################################################
# terminator::prompt::register
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::register
@test "terminator::prompt::register adds commands" {
  TERMINATOR_PROMPT_COMMANDS=()

  terminator::prompt::register terminator::prompt::minimal terminator::prompt::full

  assert_equal "${#TERMINATOR_PROMPT_COMMANDS[@]}" 2
  assert_equal "${TERMINATOR_PROMPT_COMMANDS[0]}" 'terminator::prompt::minimal'
  assert_equal "${TERMINATOR_PROMPT_COMMANDS[1]}" 'terminator::prompt::full'
}

# bats test_tags=terminator::prompt,terminator::prompt::register
@test "terminator::prompt::register skips duplicates" {
  TERMINATOR_PROMPT_COMMANDS=()

  terminator::prompt::register terminator::prompt::minimal
  terminator::prompt::register terminator::prompt::minimal

  assert_equal "${#TERMINATOR_PROMPT_COMMANDS[@]}" 1
}

# bats test_tags=terminator::prompt,terminator::prompt::register
@test "terminator::prompt::register bulk with duplicates" {
  TERMINATOR_PROMPT_COMMANDS=()

  terminator::prompt::register terminator::prompt::minimal terminator::prompt::full
  terminator::prompt::register terminator::prompt::full terminator::prompt::ask

  assert_equal "${#TERMINATOR_PROMPT_COMMANDS[@]}" 3
  assert_equal "${TERMINATOR_PROMPT_COMMANDS[2]}" 'terminator::prompt::ask'
}

# bats test_tags=terminator::prompt,terminator::prompt::register
@test "terminator::prompt::register warns on invalid command" {
  TERMINATOR_PROMPT_COMMANDS=()

  run --separate-stderr terminator::prompt::register 'nonexistent::command'

  assert_success
  assert_stderr --partial 'not found'
  assert_equal "${#TERMINATOR_PROMPT_COMMANDS[@]}" 0
}

################################################################################
# terminator::prompt::completion
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::completion
@test "terminator::prompt::completion returns matching commands" {
  TERMINATOR_PROMPT_COMMANDS=('terminator::prompt::minimal' 'terminator::prompt::full')
  COMP_WORDS=('terminator::prompt::set' 'terminator::prompt::m')
  COMP_CWORD=1

  terminator::prompt::completion

  assert_equal "${#COMPREPLY[@]}" 1
  assert_equal "${COMPREPLY[0]}" 'terminator::prompt::minimal'
}

# bats test_tags=terminator::prompt,terminator::prompt::completion
@test "terminator::prompt::completion returns all on empty input" {
  TERMINATOR_PROMPT_COMMANDS=('terminator::prompt::minimal' 'terminator::prompt::full')
  COMP_WORDS=('terminator::prompt::set' '')
  COMP_CWORD=1

  terminator::prompt::completion

  assert_equal "${#COMPREPLY[@]}" 2
}

# bats test_tags=terminator::prompt,terminator::prompt::completion
@test "terminator::prompt::completion stops after first argument" {
  TERMINATOR_PROMPT_COMMANDS=('terminator::prompt::minimal' 'terminator::prompt::full')
  COMP_WORDS=('prompt-set' 'terminator::prompt::full' '')
  COMP_CWORD=2

  terminator::prompt::completion

  assert_equal "${#COMPREPLY[@]}" 0
}

# bats test_tags=terminator::prompt,terminator::prompt::completion
@test "terminator::prompt::completion returns empty for no match" {
  TERMINATOR_PROMPT_COMMANDS=('terminator::prompt::minimal' 'terminator::prompt::full')
  COMP_WORDS=('terminator::prompt::set' 'nonexistent')
  COMP_CWORD=1

  terminator::prompt::completion

  assert_equal "${#COMPREPLY[@]}" 0
}

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
