#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/rust.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::rust::__enable__
################################################################################

# bats test_tags=terminator::rust,terminator::rust::__enable__
@test "terminator::rust::__enable__ function-exists" {
  run type -t terminator::rust::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::rust,terminator::rust::__enable__
@test "terminator::rust::__enable__ when-rustc-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::rust::__enable__

  assert_failure
}

# bats test_tags=terminator::rust,terminator::rust::__enable__
@test "terminator::rust::__enable__ when-rustc-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create fake sysroot with cargo completion file
  mkdir -p "${tmp_dir}/sysroot/etc/bash_completion.d"
  echo "# cargo completion stub" >"${tmp_dir}/sysroot/etc/bash_completion.d/cargo"

  # Create stub rustc that returns our fake sysroot for '--print sysroot'
  cat >"${tmp_dir}/rustc" <<STUB
#!/bin/sh
echo "${tmp_dir}/sysroot"
STUB
  chmod +x "${tmp_dir}/rustc"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  PATH="${tmp_dir}:${PATH}"
  run terminator::rust::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
