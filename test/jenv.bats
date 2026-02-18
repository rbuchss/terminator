#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/jenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::jenv::__enable__
################################################################################

# bats test_tags=terminator::jenv,terminator::jenv::__enable__
@test "terminator::jenv::__enable__ function-exists" {
  run type -t terminator::jenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::jenv,terminator::jenv::__enable__
@test "terminator::jenv::__enable__ when-jenv-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::jenv::__enable__

  assert_failure
}

# bats test_tags=terminator::jenv,terminator::jenv::__enable__
@test "terminator::jenv::__enable__ when-jenv-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create stub jenv that outputs no-op shell code for 'jenv init -'
  cat >"${tmp_dir}/jenv" <<'STUB'
#!/bin/sh
echo "# jenv init stub"
STUB
  chmod +x "${tmp_dir}/jenv"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  PATH="${tmp_dir}:${PATH}"
  run terminator::jenv::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
