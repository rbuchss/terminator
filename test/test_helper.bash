#!/bin/bash

function repo_root() {
  git rev-parse --show-toplevel
}

# fixtures
function test_dir_() {
  # dirname "$(readlink -f "${BASH_SOURCE[0]}")"
  dirname "$(realpath -s "${BASH_SOURCE[0]}")"
}

# shellcheck disable=SC2120
function fixture_dir() {
  local dir
  dir="$(test_dir_)/fixtures"

  if [[ "$#" -eq 1 ]]; then
    dir+="/$1"
  fi

  if ! [ -d "$dir" ]; then
    echo "ERROR: cannot find fixture dir: '$dir'" >&2
    return 1
  fi

  echo "$dir"
}

function fixture() {
  local file

  if [[ "$#" -ne 1 ]]; then
    echo "ERROR: must specify fixture file" >&2
    return 1
  fi

  # shellcheck disable=SC2119
  file="$(fixture_dir)/$1"
  if ! [ -f "$file" ]; then
    echo "ERROR: cannot find fixture file: '$file'" >&2
    return 1
  fi

  echo "$file"
}

# test functions
flunk() {
  { if [[ "$#" -eq 0 ]]; then cat -
    else echo "$*"
    fi
  }
  return 1
}

# ShellCheck doesn't know about $status from Bats
# shellcheck disable=SC2154
# shellcheck disable=SC2120
assert_success() {
  if [[ "$status" -ne 0 ]]; then
    flunk "command failed with exit status $status"
  elif [[ "$#" -gt 0 ]]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [[ "$status" -eq 0 ]]; then
    flunk "expected failed exit status"
  elif [[ "$#" -gt 0 ]]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_regexp() {
  if ! [[ "$2" =~ $1 ]]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

# ShellCheck doesn't know about $output from Bats
# shellcheck disable=SC2154
assert_output() {
  local expected
  if [[ $# -eq 0 ]]; then
    expected="$(cat -)"
  else
    expected="$1"
  fi
  assert_equal "$expected" "$output"
}

# ShellCheck doesn't know about $output from Bats
# shellcheck disable=SC2154
assert_output_exists() {
  [[ -n "$output" ]] || flunk "expected output, found none"
}

# ShellCheck doesn't know about $output from Bats
# shellcheck disable=SC2154
assert_no_output_exists() {
  [[ -z "$output" ]] || flunk "expected no output, actual:" "$output"
}

# ShellCheck doesn't know about $output from Bats
# shellcheck disable=SC2154
assert_output_contains() {
  local input="$output"; local expected="$1"; local count="${2:-1}"; local found=0
  until [ "${input/$expected/}" = "$input" ]; do
    input="${input/$expected/}"
    ((found++))
  done
  assert_equal "$count" "$found"
}

# ShellCheck doesn't know about $output from Bats
# shellcheck disable=SC2154
assert_output_regexp() {
  local expected
  if [[ $# -eq 0 ]]; then
    expected="$(cat -)"
  else
    expected="$1"
  fi
  assert_regexp "$expected" "$output"
}

# ShellCheck doesn't know about $lines from Bats
# shellcheck disable=SC2154
assert_line() {
  if [[ "$1" -ge 0 ]] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      [[ "$line" = "$1" ]] && return 0
    done
    flunk "expected line \`$1'"
  fi
}

refute_line() {
  if [[ "$1" -ge 0 ]] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [[ "$1" -lt "$num_lines" ]]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [[ "$line" = "$1" ]]; then
        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}

assert() {
  if ! "$*"; then
    flunk "failed: $*"
  fi
}

assert_exit_status() {
  assert_equal "$1" "${2:-${status}}"
}

assert_files_equal() {
  local expected actual
  expected=$1
  actual=$2
  if ! diff "$expected" "$actual" &>/tmp/$$.diff; then
    { echo "diff: $(cat /tmp/$$.diff)"
      rm /tmp/$$.diff
    } | flunk
  else
    rm /tmp/$$.diff
  fi
}

assert_file_exists() {
  local file="$1"
  if ! [ -f "$file" ]; then
    { echo "expected-file: '$file' does not exist"
    } | flunk
  fi
}

assert_file_absence() {
  local file="$1"
  if [ -f "$file" ]; then
    { echo "unexpected-file: '$file' exists"
    } | flunk
  fi
}
