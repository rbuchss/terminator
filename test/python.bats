#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/python.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::python::invoke::error
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::error
@test "terminator::python::invoke::error" {
  run --separate-stderr terminator::python::invoke::error '3'

  assert_failure 1
}

################################################################################
# terminator::python::invoke::with_system
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::with_system
@test "terminator::python::invoke::with_system with-python3" {
  if ! command -v python3 &>/dev/null; then
    skip 'python3 not available'
  fi

  run terminator::python::invoke::with_system '3'

  assert_success
  assert_output --partial 'python3'
}

# bats test_tags=terminator::python,terminator::python::invoke::with_system
@test "terminator::python::invoke::with_system with-nonexistent-version" {
  run --separate-stderr terminator::python::invoke::with_system '99'

  assert_failure
}

################################################################################
# terminator::python::invoke::with_uv
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::with_uv
@test "terminator::python::invoke::with_uv without-uv" {
  if command -v uv &>/dev/null; then
    skip 'uv is available (testing absence only)'
  fi

  run --separate-stderr terminator::python::invoke::with_uv '3'

  assert_failure
}

################################################################################
# terminator::python::invoke::with_pyenv
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::with_pyenv
@test "terminator::python::invoke::with_pyenv without-pyenv" {
  if command -v pyenv &>/dev/null; then
    skip 'pyenv is available (testing absence only)'
  fi

  run --separate-stderr terminator::python::invoke::with_pyenv '3'

  assert_failure
}

################################################################################
# terminator::python::invoke::with_homebrew
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::with_homebrew
@test "terminator::python::invoke::with_homebrew without-brew" {
  if command -v brew &>/dev/null; then
    skip 'brew is available (testing absence only)'
  fi

  run --separate-stderr terminator::python::invoke::with_homebrew '3'

  assert_failure
}
