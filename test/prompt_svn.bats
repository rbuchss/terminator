#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/prompt/svn.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::prompt::svn
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::svn,terminator::prompt::svn
@test "terminator::prompt::svn function-exists" {
  run type -t terminator::prompt::svn

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::prompt,terminator::prompt::svn,terminator::prompt::svn
@test "terminator::prompt::svn when-not-in-svn-repo" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  cd "${temp_dir}"

  run terminator::prompt::svn

  assert_success
  assert_output ''

  rm -rf "${temp_dir}"
}
