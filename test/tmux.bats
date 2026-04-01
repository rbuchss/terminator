#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/tmux.sh'

bats_require_minimum_version 1.5.0

################################################################################
# Helper: create a stub tmux script on PATH
################################################################################

_setup_tmux_stub() {
  TMUX_STUB_DIR="$(mktemp -d)"
  printf '#!/bin/sh\necho "tmux $*"\n' >"${TMUX_STUB_DIR}/tmux"
  chmod +x "${TMUX_STUB_DIR}/tmux"
  PATH="${TMUX_STUB_DIR}:${PATH}"
}

# shellcheck disable=SC2317 # invoked indirectly
_setup_tmux_stub_with_exit() {
  local exit_code="$1"
  TMUX_STUB_DIR="$(mktemp -d)"
  printf '#!/bin/sh\nexit %d\n' "${exit_code}" >"${TMUX_STUB_DIR}/tmux"
  chmod +x "${TMUX_STUB_DIR}/tmux"
  PATH="${TMUX_STUB_DIR}:${PATH}"
}

_teardown_tmux_stub() {
  if [[ -n "${TMUX_STUB_DIR}" ]]; then
    rm -rf "${TMUX_STUB_DIR}"
  fi
}

################################################################################
# Helper: create a stub tmux-session-create in a temp HOME
################################################################################

_setup_bootstrap_stub() {
  ORIGINAL_HOME="${HOME}"
  BOOTSTRAP_STUB_HOME="$(mktemp -d)"
  mkdir -p "${BOOTSTRAP_STUB_HOME}/.terminator/bin"
  cat >"${BOOTSTRAP_STUB_HOME}/.terminator/bin/tmux-session-create" <<'STUB'
echo "BOOTSTRAP_SOURCED"
STUB
  HOME="${BOOTSTRAP_STUB_HOME}"
}

_teardown_bootstrap_stub() {
  if [[ -n "${BOOTSTRAP_STUB_HOME}" ]]; then
    rm -rf "${BOOTSTRAP_STUB_HOME}"
    HOME="${ORIGINAL_HOME}"
  fi
}

################################################################################
# terminator::tmux::invoke
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke function-exists" {
  run type -t terminator::tmux::invoke

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke with-args-passes-through" {
  run terminator::tmux::invoke -V

  assert_success
  assert_output --partial 'tmux'
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke no-args-triggers-bootstrap" {
  _setup_tmux_stub
  _setup_bootstrap_stub
  unset TMUX_PATH_INITIALIZED

  run terminator::tmux::invoke

  assert_success
  assert_output --partial "BOOTSTRAP_SOURCED"

  _teardown_bootstrap_stub
  _teardown_tmux_stub
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke new-triggers-bootstrap" {
  _setup_tmux_stub
  _setup_bootstrap_stub
  unset TMUX_PATH_INITIALIZED

  run terminator::tmux::invoke new -s main

  assert_success
  assert_output --partial "BOOTSTRAP_SOURCED"
  assert_output --partial "tmux new -s main"

  _teardown_bootstrap_stub
  _teardown_tmux_stub
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke new-session-triggers-bootstrap" {
  _setup_tmux_stub
  _setup_bootstrap_stub
  unset TMUX_PATH_INITIALIZED

  run terminator::tmux::invoke new-session -s test

  assert_success
  assert_output --partial "BOOTSTRAP_SOURCED"
  assert_output --partial "tmux new-session -s test"

  _teardown_bootstrap_stub
  _teardown_tmux_stub
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke non-session-command-skips-bootstrap" {
  _setup_tmux_stub
  _setup_bootstrap_stub
  unset TMUX_PATH_INITIALIZED

  run terminator::tmux::invoke list-sessions

  assert_success
  refute_output --partial "BOOTSTRAP_SOURCED"
  assert_output --partial "tmux list-sessions"

  _teardown_bootstrap_stub
  _teardown_tmux_stub
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke initialized-skips-bootstrap" {
  _setup_tmux_stub
  _setup_bootstrap_stub
  TMUX_PATH_INITIALIZED=1

  run terminator::tmux::invoke

  assert_success
  refute_output --partial "BOOTSTRAP_SOURCED"

  unset TMUX_PATH_INITIALIZED
  _teardown_bootstrap_stub
  _teardown_tmux_stub
}

# bats test_tags=terminator::tmux,terminator::tmux::invoke
@test "terminator::tmux::invoke preserves-exit-status" {
  _setup_tmux_stub_with_exit 42
  TMUX_PATH_INITIALIZED=1

  run terminator::tmux::invoke -V

  assert_failure 42

  unset TMUX_PATH_INITIALIZED
  _teardown_tmux_stub
}

################################################################################
# terminator::tmux::__enable__
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::__enable__
@test "terminator::tmux::__enable__ function-exists" {
  run type -t terminator::tmux::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::tmux::__disable__
################################################################################

# bats test_tags=terminator::tmux,terminator::tmux::__disable__
@test "terminator::tmux::__disable__ function-exists" {
  run type -t terminator::tmux::__disable__

  assert_success
  assert_output 'function'
}
