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

################################################################################
# terminator::history::search
################################################################################

# bats test_tags=terminator::history,terminator::history::search
@test "terminator::history::search when-no-search-commands-found" {
  local original_path="${PATH}"
  # shellcheck disable=SC2123 # intentionally clearing PATH to hide all search tools
  PATH="/nonexistent"

  run terminator::history::search 'pattern'

  PATH="${original_path}"

  assert_failure 1
}

# bats test_tags=terminator::history,terminator::history::search
@test "terminator::history::search uses-first-available-command" {
  # shellcheck disable=SC2317 # invoked indirectly
  function history { echo "123 test pattern here"; }
  # shellcheck disable=SC2317 # invoked indirectly
  function less { cat; }

  run terminator::history::search 'pattern'

  assert_success
  assert_output --partial 'pattern'
}

################################################################################
# terminator::history::__enable__
################################################################################

# bats test_tags=terminator::history,terminator::history::__enable__
@test "terminator::history::__enable__ sets-aliases" {
  terminator::history::__enable__

  alias hack
  alias history_stats
  alias hideme
}

################################################################################
# terminator::history::__disable__
################################################################################

# bats test_tags=terminator::history,terminator::history::__disable__
@test "terminator::history::__disable__ removes-aliases" {
  terminator::history::__enable__
  terminator::history::__disable__

  # alias returns 1 if not defined; use explicit check since ! suppresses set -e in BATS
  local exit_code=0

  exit_code=0
  alias hack 2>/dev/null || exit_code=$?
  ((exit_code != 0))

  exit_code=0
  alias history_stats 2>/dev/null || exit_code=$?
  ((exit_code != 0))

  exit_code=0
  alias hideme 2>/dev/null || exit_code=$?
  ((exit_code != 0))
}
