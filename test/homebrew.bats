#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/homebrew.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::homebrew::is_installed
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed when-brew-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::homebrew::is_installed

  assert_failure
}

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed when-brew-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::homebrew::is_installed

  assert_success
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
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::homebrew::package::is_installed 'nonexistent'

  assert_failure
}

# bats test_tags=terminator::homebrew,terminator::homebrew::package::is_installed
@test "terminator::homebrew::package::is_installed when-package-exists" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function brew { echo "${temp_dir}"; }

  run terminator::homebrew::package::is_installed 'some-package'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::homebrew,terminator::homebrew::package::is_installed
@test "terminator::homebrew::package::is_installed when-package-not-exists" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function brew { echo "/nonexistent/path"; }

  run terminator::homebrew::package::is_installed 'some-package'

  assert_failure
}

################################################################################
# terminator::homebrew::__enable__
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::__enable__
@test "terminator::homebrew::__enable__ when-no-brew-paths-exist" {
  run --separate-stderr terminator::homebrew::__enable__

  # Returns success (bare return) with warning logged
  assert_success
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
