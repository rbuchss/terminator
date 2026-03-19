#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/rsync.sh'

bats_require_minimum_version 1.5.0

################################################################################
# Helper: create a stub rsync script on PATH
################################################################################

_setup_rsync_stub() {
  RSYNC_STUB_DIR="$(mktemp -d)"
  printf '#!/bin/sh\necho "rsync $*"\n' >"${RSYNC_STUB_DIR}/rsync"
  chmod +x "${RSYNC_STUB_DIR}/rsync"
  PATH="${RSYNC_STUB_DIR}:${PATH}"
}

_teardown_rsync_stub() {
  if [[ -n "${RSYNC_STUB_DIR}" ]]; then
    rm -rf "${RSYNC_STUB_DIR}"
  fi
}

################################################################################
# terminator::rsync::invoke
################################################################################

# bats test_tags=terminator::rsync,terminator::rsync::invoke
@test "terminator::rsync::invoke function-exists" {
  run type -t terminator::rsync::invoke

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::rsync,terminator::rsync::invoke
@test "terminator::rsync::invoke calls rsync with standard flags" {
  _setup_rsync_stub

  run terminator::rsync::invoke ./src/ user@host:~/dest/

  assert_success
  assert_output --partial "rsync -avz --progress -e ssh ./src/ user@host:~/dest/"

  _teardown_rsync_stub
}

# bats test_tags=terminator::rsync,terminator::rsync::invoke
@test "terminator::rsync::invoke includes exclude dirs" {
  _setup_rsync_stub
  TERMINATOR_RSYNC_EXCLUDE_DIRS=(.cache .venv)

  run terminator::rsync::invoke ./src/ user@host:~/dest/

  assert_success
  assert_output --partial "--exclude=.cache"
  assert_output --partial "--exclude=.venv"

  _teardown_rsync_stub
}

# bats test_tags=terminator::rsync,terminator::rsync::invoke
@test "terminator::rsync::invoke with no exclude dirs" {
  _setup_rsync_stub
  TERMINATOR_RSYNC_EXCLUDE_DIRS=()

  run terminator::rsync::invoke ./src/ user@host:~/dest/

  assert_success
  refute_output --partial "--exclude"

  _teardown_rsync_stub
}

# bats test_tags=terminator::rsync,terminator::rsync::invoke
@test "terminator::rsync::invoke prints running message" {
  _setup_rsync_stub

  run terminator::rsync::invoke ./src/ user@host:~/dest/

  assert_success
  assert_output --partial "running: rsync"

  _teardown_rsync_stub
}

################################################################################
# terminator::rsync::exclude
################################################################################

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude when-missing-dir-flag" {
  run terminator::rsync::exclude

  assert_failure 1
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude adds-single-dir" {
  TERMINATOR_RSYNC_EXCLUDE_DIRS=()

  terminator::rsync::exclude --dir .cache

  ((${#TERMINATOR_RSYNC_EXCLUDE_DIRS[@]} == 1))
  [[ "${TERMINATOR_RSYNC_EXCLUDE_DIRS[0]}" == ".cache" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude adds-multiple-dirs" {
  TERMINATOR_RSYNC_EXCLUDE_DIRS=()

  terminator::rsync::exclude --dir .cache --dir .venv

  ((${#TERMINATOR_RSYNC_EXCLUDE_DIRS[@]} == 2))
  [[ "${TERMINATOR_RSYNC_EXCLUDE_DIRS[0]}" == ".cache" ]]
  [[ "${TERMINATOR_RSYNC_EXCLUDE_DIRS[1]}" == ".venv" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude appends-to-existing" {
  TERMINATOR_RSYNC_EXCLUDE_DIRS=(.git)

  terminator::rsync::exclude --dir .cache

  ((${#TERMINATOR_RSYNC_EXCLUDE_DIRS[@]} == 2))
  [[ "${TERMINATOR_RSYNC_EXCLUDE_DIRS[0]}" == ".git" ]]
  [[ "${TERMINATOR_RSYNC_EXCLUDE_DIRS[1]}" == ".cache" ]]
}

################################################################################
# terminator::rsync::__enable__
################################################################################

# bats test_tags=terminator::rsync,terminator::rsync::__enable__
@test "terminator::rsync::__enable__ function-exists" {
  run type -t terminator::rsync::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::rsync::__disable__
################################################################################

# bats test_tags=terminator::rsync,terminator::rsync::__disable__
@test "terminator::rsync::__disable__ function-exists" {
  run type -t terminator::rsync::__disable__

  assert_success
  assert_output 'function'
}
