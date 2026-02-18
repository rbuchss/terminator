#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/rbenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::rbenv::__enable__
################################################################################

# bats test_tags=terminator::rbenv,terminator::rbenv::__enable__
@test "terminator::rbenv::__enable__ function-exists" {
  run type -t terminator::rbenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::rbenv,terminator::rbenv::__enable__
@test "terminator::rbenv::__enable__ when-rbenv-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::rbenv::__enable__

  assert_failure
}

# bats test_tags=terminator::rbenv,terminator::rbenv::__enable__
@test "terminator::rbenv::__enable__ when-rbenv-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create stub rbenv that outputs no-op shell code for 'rbenv init -'
  cat >"${tmp_dir}/rbenv" <<'STUB'
#!/bin/sh
echo "# rbenv init stub"
STUB
  chmod +x "${tmp_dir}/rbenv"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # homebrew::package::is_installed returns false (no brew) — skips completion
  PATH="${tmp_dir}:${PATH}"
  run terminator::rbenv::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
