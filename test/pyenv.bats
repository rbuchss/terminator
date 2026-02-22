#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/pyenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::pyenv::__enable__
################################################################################

# bats test_tags=terminator::pyenv,terminator::pyenv::__enable__
@test "terminator::pyenv::__enable__ function-exists" {
  run type -t terminator::pyenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::pyenv,terminator::pyenv::__enable__
@test "terminator::pyenv::__enable__ when-pyenv-not-available" {
  if command -v pyenv >/dev/null 2>&1; then
    skip 'pyenv is installed — cannot test absence'
  fi

  run terminator::pyenv::__enable__

  # Returns early with failure when pyenv not found
  assert_failure
}
