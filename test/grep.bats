#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/grep.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::grep::invoke
################################################################################

# bats test_tags=terminator::grep,terminator::grep::invoke
@test "terminator::grep::invoke matches-pattern" {
  # BusyBox grep does not support --exclude-dir
  run command grep --help
  [[ "${output}" == *'exclude-dir'* ]] || skip 'grep does not support --exclude-dir (BusyBox)'

  local temp_file
  temp_file="$(mktemp)"
  echo "hello world" >"${temp_file}"
  echo "foo bar" >>"${temp_file}"

  run terminator::grep::invoke 'hello' "${temp_file}"

  assert_success
  assert_output --partial 'hello world'

  rm -f "${temp_file}"
}

# bats test_tags=terminator::grep,terminator::grep::invoke
@test "terminator::grep::invoke no-match" {
  run command grep --help
  [[ "${output}" == *'exclude-dir'* ]] || skip 'grep does not support --exclude-dir (BusyBox)'

  local temp_file
  temp_file="$(mktemp)"
  echo "hello world" >"${temp_file}"

  run terminator::grep::invoke 'nonexistent' "${temp_file}"

  assert_failure

  rm -f "${temp_file}"
}

# bats test_tags=terminator::grep,terminator::grep::invoke
@test "terminator::grep::invoke excludes-git-directory" {
  run command grep --help
  [[ "${output}" == *'exclude-dir'* ]] || skip 'grep does not support --exclude-dir (BusyBox)'

  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/.git"
  echo "secret" >"${temp_dir}/.git/config"
  echo "public" >"${temp_dir}/file.txt"

  run terminator::grep::invoke -r 'secret' "${temp_dir}"

  # Should not find content in .git directory
  assert_failure

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::grep,terminator::grep::invoke
@test "terminator::grep::invoke excludes-svn-directory" {
  run command grep --help
  [[ "${output}" == *'exclude-dir'* ]] || skip 'grep does not support --exclude-dir (BusyBox)'

  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/.svn"
  echo "secret" >"${temp_dir}/.svn/entries"
  echo "public" >"${temp_dir}/file.txt"

  run terminator::grep::invoke -r 'secret' "${temp_dir}"

  # Should not find content in .svn directory
  assert_failure

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::grep,terminator::grep::invoke
@test "terminator::grep::invoke direct-call" {
  run command grep --help
  [[ "${output}" == *'exclude-dir'* ]] || skip 'grep does not support --exclude-dir (BusyBox)'

  local temp_file result
  temp_file="$(mktemp)"
  echo "test line" >"${temp_file}"

  result="$(terminator::grep::invoke 'test' "${temp_file}")"

  [[ "${result}" == *'test line'* ]]

  rm -f "${temp_file}"
}

################################################################################
# terminator::grep
################################################################################

# bats test_tags=terminator::grep,terminator::grep::invoke
@test "terminator::grep::invoke function-exists" {
  run type -t terminator::grep::invoke

  assert_success
  assert_output 'function'
}
