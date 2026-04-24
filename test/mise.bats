#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/mise.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::mise::__enable__
################################################################################

# bats test_tags=terminator::mise,terminator::mise::__enable__
@test "terminator::mise::__enable__ function-exists" {
  run type -t terminator::mise::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::mise,terminator::mise::__enable__
@test "terminator::mise::__enable__ when-mise-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::mise::__enable__

  assert_failure
}

# bats test_tags=terminator::mise,terminator::mise::__enable__
@test "terminator::mise::__enable__ when-mise-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Stub mise that outputs no-op shell code for 'mise activate bash'
  # and 'mise completion bash'
  cat >"${tmp_dir}/mise" <<'STUB'
#!/bin/sh
echo "# mise $* stub"
STUB
  chmod +x "${tmp_dir}/mise"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  PATH="${tmp_dir}:${PATH}"
  run terminator::mise::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
