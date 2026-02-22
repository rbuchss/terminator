#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/gcloud.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::gcloud::alias_completion
################################################################################

# bats test_tags=terminator::gcloud,terminator::gcloud::alias_completion
@test "terminator::gcloud::alias_completion function-exists" {
  run type -t terminator::gcloud::alias_completion

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::gcloud::__enable__
################################################################################

# bats test_tags=terminator::gcloud,terminator::gcloud::__enable__
@test "terminator::gcloud::__enable__ function-exists" {
  run type -t terminator::gcloud::__enable__

  assert_success
  assert_output 'function'
}
