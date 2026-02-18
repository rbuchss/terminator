#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/file.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::file::swap
################################################################################

# bats test_tags=terminator::file,terminator::file::swap
@test "terminator::file::swap no-args" {
  run --separate-stderr terminator::file::swap

  assert_failure 1
  refute_output
  assert_stderr --partial '2 arguments required'
}

# bats test_tags=terminator::file,terminator::file::swap
@test "terminator::file::swap one-arg" {
  run --separate-stderr terminator::file::swap 'file1'

  assert_failure 1
  refute_output
  assert_stderr --partial '2 arguments required'
}

# bats test_tags=terminator::file,terminator::file::swap
@test "terminator::file::swap first-file-does-not-exist" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  echo 'content2' >"${temp_dir}/file2"

  run --separate-stderr terminator::file::swap \
    "${temp_dir}/file1" "${temp_dir}/file2"

  assert_failure 1
  assert_stderr --partial 'does not exist'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::file,terminator::file::swap
@test "terminator::file::swap second-file-does-not-exist" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  echo 'content1' >"${temp_dir}/file1"

  run --separate-stderr terminator::file::swap \
    "${temp_dir}/file1" "${temp_dir}/file2"

  assert_failure 1
  assert_stderr --partial 'does not exist'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::file,terminator::file::swap
@test "terminator::file::swap success" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  echo 'content1' >"${temp_dir}/file1"
  echo 'content2' >"${temp_dir}/file2"

  run terminator::file::swap "${temp_dir}/file1" "${temp_dir}/file2"
  assert_success

  assert_equal "$(cat "${temp_dir}/file1")" 'content2'
  assert_equal "$(cat "${temp_dir}/file2")" 'content1'

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::file::read_first_line
################################################################################

# bats test_tags=terminator::file,terminator::file::read_first_line
@test "terminator::file::read_first_line success" {
  local temp_file result
  temp_file="$(mktemp)"

  printf 'first line\nsecond line\n' >"${temp_file}"

  terminator::file::read_first_line "${temp_file}" result

  assert_equal "${result}" 'first line'

  rm -f "${temp_file}"
}

# bats test_tags=terminator::file,terminator::file::read_first_line
@test "terminator::file::read_first_line empty-file" {
  local temp_file result=''
  temp_file="$(mktemp)"

  : >"${temp_file}"

  # read returns 1 on empty file (EOF with no data)
  terminator::file::read_first_line "${temp_file}" result \
    || true

  assert_equal "${result}" ''

  rm -f "${temp_file}"
}

# bats test_tags=terminator::file,terminator::file::read_first_line
@test "terminator::file::read_first_line non-existent-file" {
  local result=''

  run terminator::file::read_first_line '/nonexistent/file' result

  assert_failure
}

# bats test_tags=terminator::file,terminator::file::read_first_line
@test "terminator::file::read_first_line single-line-no-newline" {
  local temp_file result
  temp_file="$(mktemp)"

  printf 'only line' >"${temp_file}"

  # read returns 1 when there's no trailing newline, but still captures data
  terminator::file::read_first_line "${temp_file}" result \
    || true

  assert_equal "${result}" 'only line'

  rm -f "${temp_file}"
}

################################################################################
# terminator::file::mkcd
################################################################################

# bats test_tags=terminator::file,terminator::file::mkcd
@test "terminator::file::mkcd creates-and-changes-directory" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local new_dir="${temp_dir}/testdir/nested"

  terminator::file::mkcd "${new_dir}"
  local actual_pwd
  actual_pwd="$(pwd)"

  assert_equal "${actual_pwd}" "${new_dir}"

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::file::extract
################################################################################

# bats test_tags=terminator::file,terminator::file::extract
@test "terminator::file::extract non-existent-file" {
  run --separate-stderr terminator::file::extract '/nonexistent/file.tar.gz'

  assert_failure 1
  refute_output
  assert_stderr --partial 'is not a valid file'
}

# bats test_tags=terminator::file,terminator::file::extract
@test "terminator::file::extract unsupported-format" {
  local temp_dir temp_file
  temp_dir="$(mktemp -d)"
  temp_file="${temp_dir}/testfile.xyz"

  echo 'data' >"${temp_file}"

  run --separate-stderr terminator::file::extract "${temp_file}"

  assert_failure 1
  refute_output
  assert_stderr --partial 'cannot be extracted'

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::file::find_exec
################################################################################

# bats test_tags=terminator::file,terminator::file::find_exec
@test "terminator::file::find_exec no-args" {
  run --separate-stderr terminator::file::find_exec

  assert_failure 1
  refute_output
  assert_stderr --partial 'invalid # of args'
}

# bats test_tags=terminator::file,terminator::file::find_exec
@test "terminator::file::find_exec one-arg" {
  run --separate-stderr terminator::file::find_exec 'pattern'

  assert_failure 1
  refute_output
  assert_stderr --partial 'invalid # of args'
}

################################################################################
# terminator::file::dirsize
################################################################################

# bats test_tags=terminator::file,terminator::file::dirsize
@test "terminator::file::dirsize with-temp-dir" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  echo 'some data' >"${temp_dir}/testfile"

  run terminator::file::dirsize "${temp_dir}"

  assert_success

  rm -rf "${temp_dir}"
}
