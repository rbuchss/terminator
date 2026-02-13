#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/pipx.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::pipx::__enable__
################################################################################

# bats test_tags=terminator::pipx,terminator::pipx::__enable__
@test "terminator::pipx::__enable__ when-local-bin-missing" {
  local original_home="${HOME}"
  HOME="$(mktemp -d)/nonexistent"

  run terminator::pipx::__enable__

  HOME="${original_home}"

  assert_failure 1
}

# bats test_tags=terminator::pipx,terminator::pipx::__enable__
@test "terminator::pipx::__enable__ when-pipx-not-installed" {
  if command -v pipx >/dev/null 2>&1; then
    skip 'pipx is installed — cannot test absence'
  fi

  local temp_home
  temp_home="$(mktemp -d)"
  mkdir -p "${temp_home}/.local/bin"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::pipx::__enable__

  HOME="${original_home}"

  assert_failure 1

  rm -rf "${temp_home}"
}

################################################################################
# terminator::pipx::__disable__
################################################################################

# bats test_tags=terminator::pipx,terminator::pipx::__disable__
@test "terminator::pipx::__disable__ runs-without-error" {
  run terminator::pipx::__disable__

  assert_success
}
