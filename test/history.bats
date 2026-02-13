#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/history.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::history::stats
################################################################################

# bats test_tags=terminator::history,terminator::history::stats
@test "terminator::history::stats with-bash-history" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_dir}"

  printf 'ls\ncd\nls\ngit\nls\ncd\n' >"${temp_dir}/.bash_history"

  run terminator::history::stats

  HOME="${original_home}"

  assert_success
  assert_output --partial 'ls'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::history,terminator::history::stats
@test "terminator::history::stats custom-number" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_dir}"

  printf 'ls\ncd\ngit\n' >"${temp_dir}/.bash_history"

  run terminator::history::stats 2

  HOME="${original_home}"

  assert_success

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::history::search::rg
################################################################################

# bats test_tags=terminator::history,terminator::history::search::rg
@test "terminator::history::search::rg" {
  if ! command -v rg &>/dev/null; then
    skip 'rg not available'
  fi

  run terminator::history::search::rg 'pattern' <<<'test pattern here'

  assert_success
  assert_output --partial 'pattern'
}

################################################################################
# terminator::history::search::grep
################################################################################

# bats test_tags=terminator::history,terminator::history::search::grep
@test "terminator::history::search::grep" {
  run terminator::history::search::grep 'pattern' <<<'test pattern here'

  assert_success
  assert_output --partial 'pattern'
}
