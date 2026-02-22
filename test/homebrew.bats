#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/homebrew.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::homebrew::is_installed
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed when-brew-not-available" {
  if command -v brew >/dev/null 2>&1; then
    skip 'brew is installed — cannot test absence'
  fi

  run terminator::homebrew::is_installed

  assert_failure
}

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed direct-call" {
  local exit_status=0

  terminator::homebrew::is_installed || exit_status=$?

  # Just verify it runs without crashing
  [[ "${exit_status}" -eq 0 || "${exit_status}" -eq 1 ]]
}

################################################################################
# terminator::homebrew::package::is_installed
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::package::is_installed
@test "terminator::homebrew::package::is_installed when-brew-not-available" {
  if command -v brew >/dev/null 2>&1; then
    skip 'brew is installed — cannot test absence'
  fi

  run terminator::homebrew::package::is_installed 'nonexistent'

  assert_failure
}

################################################################################
# terminator::homebrew
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::add_paths
@test "terminator::homebrew::add_paths function-exists" {
  run type -t terminator::homebrew::add_paths

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::clean
@test "terminator::homebrew::clean function-exists" {
  run type -t terminator::homebrew::clean

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::cask::clean
@test "terminator::homebrew::cask::clean function-exists" {
  run type -t terminator::homebrew::cask::clean

  assert_success
  assert_output 'function'
}
