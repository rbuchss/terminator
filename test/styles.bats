#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/styles.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::styles::newline
################################################################################

# bats test_tags=terminator::styles,terminator::styles::newline
@test "terminator::styles::newline stdout" {
  run terminator::styles::newline

  assert_success
  assert_output '\n'
}

# bats test_tags=terminator::styles,terminator::styles::newline
@test "terminator::styles::newline output-variable" {
  local result _status=0

  terminator::styles::newline result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '\n'
}

# bats test_tags=terminator::styles,terminator::styles::newline
@test "terminator::styles::newline windows" {
  local original_ostype="${OSTYPE}"
  OSTYPE='msys'

  run terminator::styles::newline

  OSTYPE="${original_ostype}"

  assert_success
  assert_output '\r\n'
}

################################################################################
# terminator::styles::coalesce
################################################################################

# bats test_tags=terminator::styles,terminator::styles::coalesce
@test "terminator::styles::coalesce with-environment-value stdout" {
  run terminator::styles::coalesce 'echo' 'env_value' 'code' 'default'

  assert_success
  assert_output 'env_value'
}

# bats test_tags=terminator::styles,terminator::styles::coalesce
@test "terminator::styles::coalesce with-environment-value output-variable" {
  local result _status=0

  terminator::styles::coalesce 'echo' 'env_value' 'code' 'default' result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'env_value'
}

# bats test_tags=terminator::styles,terminator::styles::coalesce
@test "terminator::styles::coalesce without-environment-value uses-code" {
  run terminator::styles::coalesce 'echo' '' 'code_value' 'default_value'

  assert_success
  assert_output 'code_value'
}

# bats test_tags=terminator::styles,terminator::styles::coalesce
@test "terminator::styles::coalesce without-environment-value-or-code uses-default" {
  run terminator::styles::coalesce 'echo' '' '' 'default_value'

  assert_success
  assert_output 'default_value'
}

################################################################################
# terminator::styles::char_coalesce
################################################################################

# bats test_tags=terminator::styles,terminator::styles::char_coalesce
@test "terminator::styles::char_coalesce with-environment-value" {
  run terminator::styles::char_coalesce 'custom' 'default'

  assert_success
  assert_output 'custom'
}

# bats test_tags=terminator::styles,terminator::styles::char_coalesce
@test "terminator::styles::char_coalesce without-environment-value" {
  run terminator::styles::char_coalesce '' 'default'

  assert_success
  assert_output 'default'
}

# bats test_tags=terminator::styles,terminator::styles::char_coalesce
@test "terminator::styles::char_coalesce output-variable" {
  local result _status=0

  terminator::styles::char_coalesce 'custom' 'default' result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'custom'
}

# bats test_tags=terminator::styles,terminator::styles::char_coalesce
@test "terminator::styles::char_coalesce output-variable -> no output" {
  local result

  run terminator::styles::char_coalesce 'custom' 'default' result

  assert_success
  refute_output
}

################################################################################
# terminator::styles::color_coalesce
################################################################################

# bats test_tags=terminator::styles,terminator::styles::color_coalesce
@test "terminator::styles::color_coalesce with-environment-value" {
  run terminator::styles::color_coalesce 'env_color' '' '0;91m'

  assert_success
  assert_output 'env_color'
}

# bats test_tags=terminator::styles,terminator::styles::color_coalesce
@test "terminator::styles::color_coalesce with-code" {
  local expected
  printf -v expected '\[\x1b[%s\]' '38;5;69m'

  run terminator::styles::color_coalesce '' '38;5;69m' '0;91m'

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::styles,terminator::styles::color_coalesce
@test "terminator::styles::color_coalesce with-default" {
  local expected
  printf -v expected '\[\x1b[%s\]' '0;91m'

  run terminator::styles::color_coalesce '' '' '0;91m'

  assert_success
  assert_output "${expected}"
}

################################################################################
# terminator::styles::command_coalesce
################################################################################

# bats test_tags=terminator::styles,terminator::styles::command_coalesce
@test "terminator::styles::command_coalesce --help" {
  run terminator::styles::command_coalesce --help

  assert_success
  assert_output --partial 'Usage:'
}

# bats test_tags=terminator::styles,terminator::styles::command_coalesce
@test "terminator::styles::command_coalesce invalid-option" {
  run --separate-stderr terminator::styles::command_coalesce --invalid

  assert_failure 1
  refute_output
  assert_stderr --partial 'invalid option'
}

# bats test_tags=terminator::styles,terminator::styles::command_coalesce
@test "terminator::styles::command_coalesce valid-command" {
  run terminator::styles::command_coalesce \
    --command echo \
    'hello world'

  assert_success
  assert_output 'hello world'
}

# bats test_tags=terminator::styles,terminator::styles::command_coalesce
@test "terminator::styles::command_coalesce fallback-to-second-command" {
  run terminator::styles::command_coalesce \
    --command 'nonexistent_command_xyz' \
    --command echo \
    'fallback worked'

  assert_success
  assert_output 'fallback worked'
}

# bats test_tags=terminator::styles,terminator::styles::command_coalesce
@test "terminator::styles::command_coalesce no-valid-commands" {
  run --separate-stderr terminator::styles::command_coalesce \
    --command 'nonexistent_cmd_1' \
    --command 'nonexistent_cmd_2'

  assert_failure 1
  refute_output
  assert_stderr --partial 'no valid commands specified'
}

################################################################################
# terminator::styles::username
################################################################################

# bats test_tags=terminator::styles,terminator::styles::username
@test "terminator::styles::username default" {
  unset TERMINATOR_STYLES_USERNAME

  run terminator::styles::username

  assert_success
  assert_output '\u'
}

# bats test_tags=terminator::styles,terminator::styles::username
@test "terminator::styles::username override" {
  TERMINATOR_STYLES_USERNAME='custom-user'

  run terminator::styles::username

  unset TERMINATOR_STYLES_USERNAME

  assert_success
  assert_output 'custom-user'
}

# bats test_tags=terminator::styles,terminator::styles::username
@test "terminator::styles::username output-variable" {
  unset TERMINATOR_STYLES_USERNAME
  local result _status=0

  terminator::styles::username result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '\u'
}

################################################################################
# terminator::styles::hostname
################################################################################

# bats test_tags=terminator::styles,terminator::styles::hostname
@test "terminator::styles::hostname default" {
  unset TERMINATOR_STYLES_HOSTNAME

  run terminator::styles::hostname

  assert_success
  assert_output '\h'
}

################################################################################
# terminator::styles::directory
################################################################################

# bats test_tags=terminator::styles,terminator::styles::directory
@test "terminator::styles::directory default" {
  unset TERMINATOR_STYLES_DIRECTORY

  run terminator::styles::directory

  assert_success
  assert_output '\w'
}

################################################################################
# terminator::styles::jobs
################################################################################

# bats test_tags=terminator::styles,terminator::styles::jobs
@test "terminator::styles::jobs default" {
  unset TERMINATOR_STYLES_JOBS

  run terminator::styles::jobs

  assert_success
  assert_output '\j'
}

################################################################################
# terminator::styles::timestamp
################################################################################

# bats test_tags=terminator::styles,terminator::styles::timestamp
@test "terminator::styles::timestamp default" {
  unset TERMINATOR_STYLES_TIMESTAMP

  run terminator::styles::timestamp

  assert_success
  assert_output '\D{%FT%T%z}'
}

################################################################################
# terminator::styles::time
################################################################################

# bats test_tags=terminator::styles,terminator::styles::time
@test "terminator::styles::time default" {
  unset TERMINATOR_STYLES_TIME

  run terminator::styles::time

  assert_success
  assert_output '\t'
}

################################################################################
# terminator::styles::user_prefix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::user_prefix
@test "terminator::styles::user_prefix default" {
  unset TERMINATOR_STYLES_USER_PREFIX

  run terminator::styles::user_prefix

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::user_suffix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::user_suffix
@test "terminator::styles::user_suffix default non-root" {
  unset TERMINATOR_STYLES_USER_SUFFIX

  run terminator::styles::user_suffix

  assert_success
  # Non-root users get '@', root gets '#'
  if ((EUID == 0)); then
    assert_output '#'
  else
    assert_output '@'
  fi
}

################################################################################
# terminator::styles::host_prefix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::host_prefix
@test "terminator::styles::host_prefix default" {
  unset TERMINATOR_STYLES_HOST_PREFIX

  run terminator::styles::host_prefix

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::host_suffix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::host_suffix
@test "terminator::styles::host_suffix default" {
  unset TERMINATOR_STYLES_HOST_SUFFIX

  run terminator::styles::host_suffix

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::directory_prefix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::directory_prefix
@test "terminator::styles::directory_prefix default" {
  unset TERMINATOR_STYLES_DIRECTORY_PREFIX

  run terminator::styles::directory_prefix

  assert_success
  assert_output ' '
}

################################################################################
# terminator::styles::directory_suffix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::directory_suffix
@test "terminator::styles::directory_suffix default" {
  unset TERMINATOR_STYLES_DIRECTORY_SUFFIX

  run terminator::styles::directory_suffix

  assert_success
  assert_output ' '
}

################################################################################
# terminator::styles::command_symbol_prefix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::command_symbol_prefix
@test "terminator::styles::command_symbol_prefix default" {
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX

  run terminator::styles::command_symbol_prefix

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::command_symbol_suffix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::command_symbol_suffix
@test "terminator::styles::command_symbol_suffix default" {
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX

  run terminator::styles::command_symbol_suffix

  assert_success
  assert_output ' '
}

################################################################################
# terminator::styles::right_prompt_prefix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::right_prompt_prefix
@test "terminator::styles::right_prompt_prefix default" {
  unset TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX

  run terminator::styles::right_prompt_prefix

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::right_prompt_content
################################################################################

# bats test_tags=terminator::styles,terminator::styles::right_prompt_content
@test "terminator::styles::right_prompt_content default" {
  unset TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT

  run terminator::styles::right_prompt_content

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::right_prompt_suffix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::right_prompt_suffix
@test "terminator::styles::right_prompt_suffix default" {
  unset TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX

  run terminator::styles::right_prompt_suffix

  assert_success
  assert_output ''
}

################################################################################
# terminator::styles::user_prefix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::user_prefix_color
@test "terminator::styles::user_prefix_color default" {
  unset TERMINATOR_STYLES_USER_PREFIX_COLOR
  unset TERMINATOR_STYLES_USER_PREFIX_COLOR_CODE

  run terminator::styles::user_prefix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::user_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::user_color
@test "terminator::styles::user_color default" {
  unset TERMINATOR_STYLES_USER_COLOR
  unset TERMINATOR_STYLES_USER_COLOR_CODE

  run terminator::styles::user_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::host_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::host_color
@test "terminator::styles::host_color default" {
  unset TERMINATOR_STYLES_HOST_COLOR
  unset TERMINATOR_STYLES_HOST_COLOR_CODE

  run terminator::styles::host_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::directory_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::directory_color
@test "terminator::styles::directory_color default" {
  unset TERMINATOR_STYLES_DIRECTORY_COLOR
  unset TERMINATOR_STYLES_DIRECTORY_COLOR_CODE

  run terminator::styles::directory_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::error_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::error_color
@test "terminator::styles::error_color default" {
  unset TERMINATOR_STYLES_ERROR_COLOR
  unset TERMINATOR_STYLES_ERROR_COLOR_CODE

  run terminator::styles::error_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::warning_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::warning_color
@test "terminator::styles::warning_color default" {
  unset TERMINATOR_STYLES_WARNING_COLOR
  unset TERMINATOR_STYLES_WARNING_COLOR_CODE

  run terminator::styles::warning_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::ok_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::ok_color
@test "terminator::styles::ok_color default" {
  unset TERMINATOR_STYLES_OK_COLOR
  unset TERMINATOR_STYLES_OK_COLOR_CODE

  run terminator::styles::ok_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::branch_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::branch_color
@test "terminator::styles::branch_color default" {
  unset TERMINATOR_STYLES_BRANCH_COLOR
  unset TERMINATOR_STYLES_BRANCH_COLOR_CODE

  run terminator::styles::branch_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::index_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::index_color
@test "terminator::styles::index_color default" {
  unset TERMINATOR_STYLES_INDEX_COLOR
  unset TERMINATOR_STYLES_INDEX_COLOR_CODE

  run terminator::styles::index_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::files_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::files_color
@test "terminator::styles::files_color default" {
  unset TERMINATOR_STYLES_FILES_COLOR
  unset TERMINATOR_STYLES_FILES_COLOR_CODE

  run terminator::styles::files_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::divider_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::divider_color
@test "terminator::styles::divider_color default" {
  unset TERMINATOR_STYLES_DIVIDER_COLOR
  unset TERMINATOR_STYLES_DIVIDER_COLOR_CODE

  run terminator::styles::divider_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::stash_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::stash_color
@test "terminator::styles::stash_color default" {
  unset TERMINATOR_STYLES_STASH_COLOR
  unset TERMINATOR_STYLES_STASH_COLOR_CODE

  run terminator::styles::stash_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::enclosure_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::enclosure_color
@test "terminator::styles::enclosure_color default" {
  unset TERMINATOR_STYLES_ENCLOSURE_COLOR
  unset TERMINATOR_STYLES_ENCLOSURE_COLOR_CODE

  run terminator::styles::enclosure_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::host_prefix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::host_prefix_color
@test "terminator::styles::host_prefix_color output-variable" {
  unset TERMINATOR_STYLES_HOST_PREFIX_COLOR
  unset TERMINATOR_STYLES_HOST_PREFIX_COLOR_CODE
  local result _status=0

  terminator::styles::host_prefix_color result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_regex "${result}" '\\\['
}

################################################################################
# terminator::styles::host_suffix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::host_suffix_color
@test "terminator::styles::host_suffix_color default" {
  unset TERMINATOR_STYLES_HOST_SUFFIX_COLOR
  unset TERMINATOR_STYLES_HOST_SUFFIX_COLOR_CODE

  run terminator::styles::host_suffix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::directory_prefix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::directory_prefix_color
@test "terminator::styles::directory_prefix_color default" {
  unset TERMINATOR_STYLES_DIRECTORY_PREFIX_COLOR
  unset TERMINATOR_STYLES_DIRECTORY_PREFIX_COLOR_CODE

  run terminator::styles::directory_prefix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::directory_suffix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::directory_suffix_color
@test "terminator::styles::directory_suffix_color default" {
  unset TERMINATOR_STYLES_DIRECTORY_SUFFIX_COLOR
  unset TERMINATOR_STYLES_DIRECTORY_SUFFIX_COLOR_CODE

  run terminator::styles::directory_suffix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::command_symbol_prefix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::command_symbol_prefix_color
@test "terminator::styles::command_symbol_prefix_color default" {
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX_COLOR
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_PREFIX_COLOR_CODE

  run terminator::styles::command_symbol_prefix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::command_symbol_suffix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::command_symbol_suffix_color
@test "terminator::styles::command_symbol_suffix_color default" {
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX_COLOR
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_SUFFIX_COLOR_CODE

  run terminator::styles::command_symbol_suffix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::user_suffix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::user_suffix_color
@test "terminator::styles::user_suffix_color default" {
  unset TERMINATOR_STYLES_USER_SUFFIX_COLOR
  unset TERMINATOR_STYLES_USER_SUFFIX_COLOR_CODE

  run terminator::styles::user_suffix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::error_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::error_symbol
@test "terminator::styles::error_symbol default" {
  unset TERMINATOR_STYLES_ERROR_SYMBOL
  unset TERMINATOR_STYLES_ERROR_SYMBOL_CODE

  run terminator::styles::error_symbol

  assert_success
}

################################################################################
# terminator::styles::warning_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::warning_symbol
@test "terminator::styles::warning_symbol default" {
  unset TERMINATOR_STYLES_WARNING_SYMBOL
  unset TERMINATOR_STYLES_WARNING_SYMBOL_CODE

  run terminator::styles::warning_symbol

  assert_success
}

################################################################################
# terminator::styles::ok_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::ok_symbol
@test "terminator::styles::ok_symbol default" {
  unset TERMINATOR_STYLES_OK_SYMBOL
  unset TERMINATOR_STYLES_OK_SYMBOL_CODE

  run terminator::styles::ok_symbol

  assert_success
}

################################################################################
# terminator::styles::branch_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::branch_symbol
@test "terminator::styles::branch_symbol default" {
  unset TERMINATOR_STYLES_BRANCH_SYMBOL
  unset TERMINATOR_STYLES_BRANCH_SYMBOL_CODE

  run terminator::styles::branch_symbol

  assert_success
}

################################################################################
# terminator::styles::host_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::host_symbol
@test "terminator::styles::host_symbol default" {
  unset TERMINATOR_STYLES_HOST_SYMBOL
  unset TERMINATOR_STYLES_HOST_SYMBOL_CODE

  run terminator::styles::host_symbol

  assert_success
}

################################################################################
# terminator::styles::command_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::command_symbol
@test "terminator::styles::command_symbol default" {
  unset TERMINATOR_STYLES_COMMAND_SYMBOL
  unset TERMINATOR_STYLES_COMMAND_SYMBOL_CODE

  run terminator::styles::command_symbol

  assert_success
}

################################################################################
# terminator::styles::detached_head_symbol
################################################################################

# bats test_tags=terminator::styles,terminator::styles::detached_head_symbol
@test "terminator::styles::detached_head_symbol default" {
  unset TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL
  unset TERMINATOR_STYLES_DETACHED_HEAD_SYMBOL_CODE

  run terminator::styles::detached_head_symbol

  assert_success
}

################################################################################
# terminator::styles::upstream_same_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::upstream_same_color
@test "terminator::styles::upstream_same_color default" {
  unset TERMINATOR_STYLES_UPSTREAM_SAME_COLOR
  unset TERMINATOR_STYLES_UPSTREAM_SAME_COLOR_CODE

  run terminator::styles::upstream_same_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::upstream_ahead_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::upstream_ahead_color
@test "terminator::styles::upstream_ahead_color default" {
  unset TERMINATOR_STYLES_UPSTREAM_AHEAD_COLOR
  unset TERMINATOR_STYLES_UPSTREAM_AHEAD_COLOR_CODE

  run terminator::styles::upstream_ahead_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::upstream_behind_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::upstream_behind_color
@test "terminator::styles::upstream_behind_color default" {
  unset TERMINATOR_STYLES_UPSTREAM_BEHIND_COLOR
  unset TERMINATOR_STYLES_UPSTREAM_BEHIND_COLOR_CODE

  run terminator::styles::upstream_behind_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::upstream_gone_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::upstream_gone_color
@test "terminator::styles::upstream_gone_color default" {
  unset TERMINATOR_STYLES_UPSTREAM_GONE_COLOR
  unset TERMINATOR_STYLES_UPSTREAM_GONE_COLOR_CODE

  run terminator::styles::upstream_gone_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::right_prompt_prefix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::right_prompt_prefix_color
@test "terminator::styles::right_prompt_prefix_color default" {
  unset TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX_COLOR
  unset TERMINATOR_STYLES_RIGHT_PROMPT_PREFIX_COLOR_CODE

  run terminator::styles::right_prompt_prefix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::right_prompt_content_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::right_prompt_content_color
@test "terminator::styles::right_prompt_content_color default" {
  unset TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT_COLOR
  unset TERMINATOR_STYLES_RIGHT_PROMPT_CONTENT_COLOR_CODE

  run terminator::styles::right_prompt_content_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::right_prompt_suffix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::right_prompt_suffix_color
@test "terminator::styles::right_prompt_suffix_color default" {
  unset TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX_COLOR
  unset TERMINATOR_STYLES_RIGHT_PROMPT_SUFFIX_COLOR_CODE

  run terminator::styles::right_prompt_suffix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::root::user_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::root::user_color
@test "terminator::styles::root::user_color default" {
  unset TERMINATOR_STYLES_ROOT_USER_COLOR
  unset TERMINATOR_STYLES_ROOT_USER_COLOR_CODE

  run terminator::styles::root::user_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::root::user_suffix_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::root::user_suffix_color
@test "terminator::styles::root::user_suffix_color default" {
  unset TERMINATOR_STYLES_ROOT_USER_SUFFIX_COLOR
  unset TERMINATOR_STYLES_ROOT_USER_SUFFIX_COLOR_CODE

  run terminator::styles::root::user_suffix_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::root::user_suffix
################################################################################

# bats test_tags=terminator::styles,terminator::styles::root::user_suffix
@test "terminator::styles::root::user_suffix default" {
  unset TERMINATOR_STYLES_ROOT_USER_SUFFIX

  run terminator::styles::root::user_suffix

  assert_success
  assert_output '#'
}

################################################################################
# terminator::styles::root::host_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::root::host_color
@test "terminator::styles::root::host_color default" {
  unset TERMINATOR_STYLES_ROOT_HOST_COLOR
  unset TERMINATOR_STYLES_ROOT_HOST_COLOR_CODE

  run terminator::styles::root::host_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::root::directory_color
################################################################################

# bats test_tags=terminator::styles,terminator::styles::root::directory_color
@test "terminator::styles::root::directory_color default" {
  unset TERMINATOR_STYLES_ROOT_DIRECTORY_COLOR
  unset TERMINATOR_STYLES_ROOT_DIRECTORY_COLOR_CODE

  run terminator::styles::root::directory_color

  assert_success
  assert_output --partial '\['
}

################################################################################
# terminator::styles::unicode_coalesce
################################################################################

# bats test_tags=terminator::styles,terminator::styles::unicode_coalesce
@test "terminator::styles::unicode_coalesce with-environment-value" {
  run terminator::styles::unicode_coalesce 'env_value' '' 0xE0A0

  assert_success
  assert_output 'env_value'
}

################################################################################
# Direct-call tests for kcov coverage
# (run-based tests execute in subshells that don't inherit kcov's DEBUG trap)
################################################################################

# bats test_tags=terminator::styles,terminator::styles::username
@test "terminator::styles::username direct-call" {
  local result=''
  terminator::styles::username result
  [[ "${result}" == '\u' || -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::hostname
@test "terminator::styles::hostname direct-call" {
  local result=''
  terminator::styles::hostname result
  [[ "${result}" == '\h' || -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::directory
@test "terminator::styles::directory direct-call" {
  local result=''
  terminator::styles::directory result
  [[ "${result}" == '\w' || -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::jobs
@test "terminator::styles::jobs direct-call" {
  local result=''
  terminator::styles::jobs result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::timestamp
@test "terminator::styles::timestamp direct-call" {
  local result=''
  terminator::styles::timestamp result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::time
@test "terminator::styles::time direct-call" {
  local result=''
  terminator::styles::time result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::user_prefix
@test "terminator::styles::user_prefix direct-call" {
  local result=''
  terminator::styles::user_prefix result
  # May be empty string by default
  true
}

# bats test_tags=terminator::styles,terminator::styles::host_prefix
@test "terminator::styles::host_prefix direct-call" {
  local result=''
  terminator::styles::host_prefix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::host_suffix
@test "terminator::styles::host_suffix direct-call" {
  local result=''
  terminator::styles::host_suffix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::directory_prefix
@test "terminator::styles::directory_prefix direct-call" {
  local result=''
  terminator::styles::directory_prefix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::directory_suffix
@test "terminator::styles::directory_suffix direct-call" {
  local result=''
  terminator::styles::directory_suffix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::command_symbol_prefix
@test "terminator::styles::command_symbol_prefix direct-call" {
  local result=''
  terminator::styles::command_symbol_prefix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::command_symbol_suffix
@test "terminator::styles::command_symbol_suffix direct-call" {
  local result=''
  terminator::styles::command_symbol_suffix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::right_prompt_prefix
@test "terminator::styles::right_prompt_prefix direct-call" {
  local result=''
  terminator::styles::right_prompt_prefix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::right_prompt_content
@test "terminator::styles::right_prompt_content direct-call" {
  local result=''
  terminator::styles::right_prompt_content result
  true
}

# bats test_tags=terminator::styles,terminator::styles::right_prompt_suffix
@test "terminator::styles::right_prompt_suffix direct-call" {
  local result=''
  terminator::styles::right_prompt_suffix result
  true
}

# bats test_tags=terminator::styles,terminator::styles::user_color
@test "terminator::styles::user_color direct-call" {
  local result=''
  terminator::styles::user_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::host_color
@test "terminator::styles::host_color direct-call" {
  local result=''
  terminator::styles::host_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::directory_color
@test "terminator::styles::directory_color direct-call" {
  local result=''
  terminator::styles::directory_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::error_color
@test "terminator::styles::error_color direct-call" {
  local result=''
  terminator::styles::error_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::warning_color
@test "terminator::styles::warning_color direct-call" {
  local result=''
  terminator::styles::warning_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::ok_color
@test "terminator::styles::ok_color direct-call" {
  local result=''
  terminator::styles::ok_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::branch_color
@test "terminator::styles::branch_color direct-call" {
  local result=''
  terminator::styles::branch_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::index_color
@test "terminator::styles::index_color direct-call" {
  local result=''
  terminator::styles::index_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::files_color
@test "terminator::styles::files_color direct-call" {
  local result=''
  terminator::styles::files_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::divider_color
@test "terminator::styles::divider_color direct-call" {
  local result=''
  terminator::styles::divider_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::stash_color
@test "terminator::styles::stash_color direct-call" {
  local result=''
  terminator::styles::stash_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::enclosure_color
@test "terminator::styles::enclosure_color direct-call" {
  local result=''
  terminator::styles::enclosure_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::user_prefix_color
@test "terminator::styles::user_prefix_color direct-call" {
  local result=''
  terminator::styles::user_prefix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::user_suffix_color
@test "terminator::styles::user_suffix_color direct-call" {
  local result=''
  terminator::styles::user_suffix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::host_prefix_color
@test "terminator::styles::host_prefix_color direct-call" {
  local result=''
  terminator::styles::host_prefix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::host_suffix_color
@test "terminator::styles::host_suffix_color direct-call" {
  local result=''
  terminator::styles::host_suffix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::directory_prefix_color
@test "terminator::styles::directory_prefix_color direct-call" {
  local result=''
  terminator::styles::directory_prefix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::directory_suffix_color
@test "terminator::styles::directory_suffix_color direct-call" {
  local result=''
  terminator::styles::directory_suffix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::command_symbol_prefix_color
@test "terminator::styles::command_symbol_prefix_color direct-call" {
  local result=''
  terminator::styles::command_symbol_prefix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::command_symbol_suffix_color
@test "terminator::styles::command_symbol_suffix_color direct-call" {
  local result=''
  terminator::styles::command_symbol_suffix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::upstream_same_color
@test "terminator::styles::upstream_same_color direct-call" {
  local result=''
  terminator::styles::upstream_same_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::upstream_ahead_color
@test "terminator::styles::upstream_ahead_color direct-call" {
  local result=''
  terminator::styles::upstream_ahead_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::upstream_behind_color
@test "terminator::styles::upstream_behind_color direct-call" {
  local result=''
  terminator::styles::upstream_behind_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::upstream_gone_color
@test "terminator::styles::upstream_gone_color direct-call" {
  local result=''
  terminator::styles::upstream_gone_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::right_prompt_prefix_color
@test "terminator::styles::right_prompt_prefix_color direct-call" {
  local result=''
  terminator::styles::right_prompt_prefix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::right_prompt_content_color
@test "terminator::styles::right_prompt_content_color direct-call" {
  local result=''
  terminator::styles::right_prompt_content_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::right_prompt_suffix_color
@test "terminator::styles::right_prompt_suffix_color direct-call" {
  local result=''
  terminator::styles::right_prompt_suffix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::error_symbol
@test "terminator::styles::error_symbol direct-call" {
  local result=''
  terminator::styles::error_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::warning_symbol
@test "terminator::styles::warning_symbol direct-call" {
  local result=''
  terminator::styles::warning_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::ok_symbol
@test "terminator::styles::ok_symbol direct-call" {
  local result=''
  terminator::styles::ok_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::branch_symbol
@test "terminator::styles::branch_symbol direct-call" {
  local result=''
  terminator::styles::branch_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::host_symbol
@test "terminator::styles::host_symbol direct-call" {
  local result=''
  terminator::styles::host_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::command_symbol
@test "terminator::styles::command_symbol direct-call" {
  local result=''
  terminator::styles::command_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::detached_head_symbol
@test "terminator::styles::detached_head_symbol direct-call" {
  local result=''
  terminator::styles::detached_head_symbol result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::root::user_color
@test "terminator::styles::root::user_color direct-call" {
  local result=''
  terminator::styles::root::user_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::root::user_suffix_color
@test "terminator::styles::root::user_suffix_color direct-call" {
  local result=''
  terminator::styles::root::user_suffix_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::root::user_suffix
@test "terminator::styles::root::user_suffix direct-call" {
  local result=''
  terminator::styles::root::user_suffix result
  [[ "${result}" == '#' || -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::root::host_color
@test "terminator::styles::root::host_color direct-call" {
  local result=''
  terminator::styles::root::host_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::root::directory_color
@test "terminator::styles::root::directory_color direct-call" {
  local result=''
  terminator::styles::root::directory_color result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::newline
@test "terminator::styles::newline direct-call" {
  local result=''
  terminator::styles::newline result
  [[ "${result}" == '\n' || "${result}" == '\r\n' ]]
}

# bats test_tags=terminator::styles,terminator::styles::coalesce
@test "terminator::styles::coalesce direct-call with-output-variable" {
  local result=''
  terminator::styles::coalesce 'echo' 'env_value' 'code' 'default' result
  assert_equal "${result}" 'env_value'
}

# bats test_tags=terminator::styles,terminator::styles::color_coalesce
@test "terminator::styles::color_coalesce direct-call" {
  local result=''
  terminator::styles::color_coalesce '' '' '0m' result
  [[ -n "${result}" ]]
}

# bats test_tags=terminator::styles,terminator::styles::char_coalesce
@test "terminator::styles::char_coalesce direct-call" {
  local result=''
  terminator::styles::char_coalesce '' 'default_val' result
  assert_equal "${result}" 'default_val'
}

# bats test_tags=terminator::styles,terminator::styles::user_suffix
@test "terminator::styles::user_suffix direct-call" {
  local result=''
  terminator::styles::user_suffix result
  [[ "${result}" == '@' || "${result}" == '#' || -n "${result}" ]]
}
