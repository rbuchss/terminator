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
@test "terminator::rsync::invoke includes excludes" {
  _setup_rsync_stub
  TERMINATOR_RSYNC_EXCLUDES=(.cache .venv)

  run terminator::rsync::invoke ./src/ user@host:~/dest/

  assert_success
  assert_output --partial "--exclude=.cache"
  assert_output --partial "--exclude=.venv"

  _teardown_rsync_stub
}

# bats test_tags=terminator::rsync,terminator::rsync::invoke
@test "terminator::rsync::invoke with no excludes" {
  _setup_rsync_stub
  TERMINATOR_RSYNC_EXCLUDES=()

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
@test "terminator::rsync::exclude when-missing-flag" {
  run terminator::rsync::exclude

  assert_failure 1
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude adds-single-dir" {
  TERMINATOR_RSYNC_EXCLUDES=()

  terminator::rsync::exclude --dir .cache

  ((${#TERMINATOR_RSYNC_EXCLUDES[@]} == 1))
  [[ "${TERMINATOR_RSYNC_EXCLUDES[0]}" == ".cache" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude adds-multiple-dirs" {
  TERMINATOR_RSYNC_EXCLUDES=()

  terminator::rsync::exclude --dir .cache --dir .venv

  ((${#TERMINATOR_RSYNC_EXCLUDES[@]} == 2))
  [[ "${TERMINATOR_RSYNC_EXCLUDES[0]}" == ".cache" ]]
  [[ "${TERMINATOR_RSYNC_EXCLUDES[1]}" == ".venv" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude appends-to-existing" {
  TERMINATOR_RSYNC_EXCLUDES=(.git)

  terminator::rsync::exclude --dir .cache

  ((${#TERMINATOR_RSYNC_EXCLUDES[@]} == 2))
  [[ "${TERMINATOR_RSYNC_EXCLUDES[0]}" == ".git" ]]
  [[ "${TERMINATOR_RSYNC_EXCLUDES[1]}" == ".cache" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude adds-file" {
  TERMINATOR_RSYNC_EXCLUDES=()

  terminator::rsync::exclude --file .env

  ((${#TERMINATOR_RSYNC_EXCLUDES[@]} == 1))
  [[ "${TERMINATOR_RSYNC_EXCLUDES[0]}" == ".env" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude adds-pattern" {
  TERMINATOR_RSYNC_EXCLUDES=()

  terminator::rsync::exclude --pattern '*.deb'

  ((${#TERMINATOR_RSYNC_EXCLUDES[@]} == 1))
  [[ "${TERMINATOR_RSYNC_EXCLUDES[0]}" == "*.deb" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude mixes-dir-file-pattern" {
  TERMINATOR_RSYNC_EXCLUDES=()

  terminator::rsync::exclude --dir .cache --file .env --pattern '*.tgz'

  ((${#TERMINATOR_RSYNC_EXCLUDES[@]} == 3))
  [[ "${TERMINATOR_RSYNC_EXCLUDES[0]}" == ".cache" ]]
  [[ "${TERMINATOR_RSYNC_EXCLUDES[1]}" == ".env" ]]
  [[ "${TERMINATOR_RSYNC_EXCLUDES[2]}" == "*.tgz" ]]
}

# bats test_tags=terminator::rsync,terminator::rsync::exclude
@test "terminator::rsync::exclude rejects-unknown-flag" {
  run terminator::rsync::exclude --bogus foo

  assert_failure 1
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
