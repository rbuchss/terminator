#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/nodenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::nodenv::__enable__
################################################################################

# bats test_tags=terminator::nodenv,terminator::nodenv::__enable__
@test "terminator::nodenv::__enable__ function-exists" {
  run type -t terminator::nodenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::nodenv,terminator::nodenv::__enable__
@test "terminator::nodenv::__enable__ when-nodenv-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::nodenv::__enable__

  assert_failure
}

# bats test_tags=terminator::nodenv,terminator::nodenv::__enable__
@test "terminator::nodenv::__enable__ when-nodenv-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create stub nodenv that outputs no-op shell code for 'nodenv init -'
  cat >"${tmp_dir}/nodenv" <<'STUB'
#!/bin/sh
echo "# nodenv init stub"
STUB
  chmod +x "${tmp_dir}/nodenv"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # homebrew::package::is_installed returns false (no brew) — skips completion
  PATH="${tmp_dir}:${PATH}"
  run terminator::nodenv::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
