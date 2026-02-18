#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/python.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::python::__enable__
################################################################################

# bats test_tags=terminator::python,terminator::python::__enable__
@test "terminator::python::__enable__ when-python-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::any_exist { return 1; }

  run terminator::python::__enable__

  assert_failure
}

# bats test_tags=terminator::python,terminator::python::__enable__
@test "terminator::python::__enable__ when-python-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::any_exist { return 0; }

  terminator::python::__enable__

  alias py
}

################################################################################
# terminator::python::__disable__
################################################################################

# bats test_tags=terminator::python,terminator::python::__disable__
@test "terminator::python::__disable__ removes-alias" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::any_exist { return 0; }

  terminator::python::__enable__
  terminator::python::__disable__

  # alias returns 1 if not defined; use explicit check since ! suppresses set -e in BATS
  local exit_code=0
  alias py 2>/dev/null || exit_code=$?
  ((exit_code != 0))
}

################################################################################
# terminator::python::invoke
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke
@test "terminator::python::invoke when-all-providers-fail" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_uv { return 1; }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_pyenv { return 1; }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_homebrew { return 1; }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_system { return 1; }

  run --separate-stderr terminator::python::invoke

  assert_failure 1
}

# bats test_tags=terminator::python,terminator::python::invoke
@test "terminator::python::invoke uses-first-successful-provider" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local mock_python="${temp_dir}/mock-python"
  printf '#!/bin/sh\necho "hello from mock python"\n' >"${mock_python}"
  chmod +x "${mock_python}"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_uv { return 1; }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_pyenv { echo "${mock_python}"; }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_homebrew { return 1; }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::python::invoke::with_system { return 1; }

  run --separate-stderr terminator::python::invoke

  assert_success
  assert_output 'hello from mock python'

  rm -rf "${temp_dir}"
}

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
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run --separate-stderr terminator::python::invoke::with_uv '3'

  assert_failure
}

# bats test_tags=terminator::python,terminator::python::invoke::with_uv
@test "terminator::python::invoke::with_uv with-uv-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function uv { echo "/mock/path/python3"; }

  run --separate-stderr terminator::python::invoke::with_uv '3'

  assert_success
  assert_output '/mock/path/python3'
}

################################################################################
# terminator::python::invoke::with_pyenv
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::with_pyenv
@test "terminator::python::invoke::with_pyenv without-pyenv" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run --separate-stderr terminator::python::invoke::with_pyenv '3'

  assert_failure
}

# bats test_tags=terminator::python,terminator::python::invoke::with_pyenv
@test "terminator::python::invoke::with_pyenv with-pyenv-installed" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/shims"
  touch "${temp_dir}/shims/python3.12"
  chmod +x "${temp_dir}/shims/python3.12"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function pyenv {
    case "$1" in
      latest) echo "3.12.1" ;;
      root) echo "${temp_dir}" ;;
    esac
  }

  run --separate-stderr terminator::python::invoke::with_pyenv '3'

  assert_success
  assert_output "${temp_dir}/shims/python3.12"

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::python::invoke::with_homebrew
################################################################################

# bats test_tags=terminator::python,terminator::python::invoke::with_homebrew
@test "terminator::python::invoke::with_homebrew without-brew" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run --separate-stderr terminator::python::invoke::with_homebrew '3'

  assert_failure
}

# bats test_tags=terminator::python,terminator::python::invoke::with_homebrew
@test "terminator::python::invoke::with_homebrew with-brew-installed" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/bin"
  touch "${temp_dir}/bin/python3"
  chmod +x "${temp_dir}/bin/python3"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function brew { echo "${temp_dir}"; }

  run --separate-stderr terminator::python::invoke::with_homebrew '3'

  assert_success
  assert_output "${temp_dir}/bin/python3"

  rm -rf "${temp_dir}"
}
