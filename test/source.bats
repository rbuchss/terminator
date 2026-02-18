#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/source.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::source
################################################################################

# bats test_tags=terminator::source,terminator::source::source
@test "terminator::source with-valid-file" {
  local temp_dir temp_file
  temp_dir="$(mktemp -d)"
  temp_file="${temp_dir}/test_source.sh"

  echo 'SOURCE_TEST_VAR=loaded' >"${temp_file}"

  terminator::source "${temp_file}"

  assert_equal "${SOURCE_TEST_VAR}" 'loaded'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::source,terminator::source::source
@test "terminator::source with-nonexistent-file" {
  run --separate-stderr terminator::source '/nonexistent/file.sh'

  assert_success
}

# bats test_tags=terminator::source,terminator::source::source
@test "terminator::source with-empty-file" {
  local temp_dir temp_file
  temp_dir="$(mktemp -d)"
  temp_file="${temp_dir}/empty.sh"

  : >"${temp_file}"

  run --separate-stderr terminator::source "${temp_file}"

  # Empty (zero-size) file should trigger warning since -s checks for non-empty
  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::source,terminator::source::source
@test "terminator::source with-multiple-files" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  echo 'SOURCE_MULTI_A=a' >"${temp_dir}/a.sh"
  echo 'SOURCE_MULTI_B=b' >"${temp_dir}/b.sh"

  terminator::source "${temp_dir}/a.sh" "${temp_dir}/b.sh"

  assert_equal "${SOURCE_MULTI_A}" 'a'
  assert_equal "${SOURCE_MULTI_B}" 'b'

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::source::bash_profile
################################################################################

# bats test_tags=terminator::source,terminator::source::bash_profile
@test "terminator::source::bash_profile --help" {
  run terminator::source::bash_profile --help

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial '--force'
}

# bats test_tags=terminator::source,terminator::source::bash_profile
@test "terminator::source::bash_profile invalid-option" {
  run --separate-stderr terminator::source::bash_profile --invalid

  assert_failure 1
  assert_stderr --partial 'invalid option'
}

################################################################################
# terminator::source::bash_profile::usage
################################################################################

# bats test_tags=terminator::source,terminator::source::bash_profile::usage
@test "terminator::source::bash_profile::usage" {
  run terminator::source::bash_profile::usage

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial '--force'
}

################################################################################
# terminator::source::__enable__
################################################################################

# bats test_tags=terminator::source,terminator::source::__enable__
@test "terminator::source::__enable__ sets-aliases" {
  terminator::source::__enable__

  alias source_bash_profile
  alias sbp
}

################################################################################
# terminator::source::__disable__
################################################################################

# bats test_tags=terminator::source,terminator::source::__disable__
@test "terminator::source::__disable__ removes-aliases" {
  terminator::source::__enable__
  terminator::source::__disable__

  local exit_code=0

  exit_code=0
  alias source_bash_profile 2>/dev/null || exit_code=$?
  ((exit_code != 0))

  exit_code=0
  alias sbp 2>/dev/null || exit_code=$?
  ((exit_code != 0))
}

################################################################################
# terminator::source::bash_profile::completion::add_alias
################################################################################

# bats test_tags=terminator::source,terminator::source::bash_profile::completion::add_alias
@test "terminator::source::bash_profile::completion::add_alias registers-completion" {
  terminator::source::bash_profile::completion::add_alias 'test_alias'

  run complete -p test_alias

  assert_success
  assert_output --partial 'terminator::source::bash_profile::completion'
}

################################################################################
# terminator::source::bash_profile::completion::remove_alias
################################################################################

# bats test_tags=terminator::source,terminator::source::bash_profile::completion::remove_alias
@test "terminator::source::bash_profile::completion::remove_alias removes-completion" {
  terminator::source::bash_profile::completion::add_alias 'test_alias'
  terminator::source::bash_profile::completion::remove_alias 'test_alias'

  run complete -p test_alias

  assert_failure
}
