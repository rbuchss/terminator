#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/terraform.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::terraform::__enable__
################################################################################

# bats test_tags=terminator::terraform,terminator::terraform::__enable__
@test "terminator::terraform::__enable__ function-exists" {
  run type -t terminator::terraform::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::terraform,terminator::terraform::__enable__
@test "terminator::terraform::__enable__ when-terraform-not-available" {
  if command -v terraform >/dev/null 2>&1; then
    skip 'terraform is installed — cannot test absence'
  fi

  run terminator::terraform::__enable__

  # Returns early with failure when terraform not found
  assert_failure
}
