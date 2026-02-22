#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/claude.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::claude::__enable__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::__enable__
@test "terminator::claude::__enable__ when-local-bin-missing" {
  local original_home="${HOME}"
  HOME="$(mktemp -d)/nonexistent"

  run terminator::claude::__enable__

  HOME="${original_home}"

  assert_failure 1
}

# bats test_tags=terminator::claude,terminator::claude::__enable__
@test "terminator::claude::__enable__ when-claude-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  local temp_home
  temp_home="$(mktemp -d)"
  mkdir -p "${temp_home}/.local/bin"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::__enable__

  HOME="${original_home}"

  assert_failure 1

  rm -rf "${temp_home}"
}

################################################################################
# terminator::claude::__disable__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::__disable__
@test "terminator::claude::__disable__ runs-without-error" {
  run terminator::claude::__disable__

  assert_success
}

################################################################################
# terminator::claude
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::add::context7
@test "terminator::claude::mcp::add::context7 function-exists" {
  run type -t terminator::claude::mcp::add::context7

  assert_success
  assert_output 'function'
}
