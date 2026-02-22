#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/go.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::go::__enable__
################################################################################

# bats test_tags=terminator::go,terminator::go::__enable__
@test "terminator::go::__enable__ function-exists" {
  run type -t terminator::go::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::go,terminator::go::__enable__
@test "terminator::go::__enable__ when-go-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::go::__enable__

  assert_failure
}

# bats test_tags=terminator::go,terminator::go::__enable__
@test "terminator::go::__enable__ when-go-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create fake GOPATH/bin directory
  mkdir -p "${tmp_dir}/gopath/bin"

  # Create stub go that returns our fake GOPATH for 'go env GOPATH'
  cat >"${tmp_dir}/go" <<STUB
#!/bin/sh
echo "${tmp_dir}/gopath"
STUB
  chmod +x "${tmp_dir}/go"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  PATH="${tmp_dir}:${PATH}"
  run terminator::go::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}

################################################################################
# terminator::go::__disable__
################################################################################

# bats test_tags=terminator::go,terminator::go::__disable__
@test "terminator::go::__disable__ function-exists" {
  run type -t terminator::go::__disable__

  assert_success
  assert_output 'function'
}
