#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/dircolors.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::dircolors::__enable__
################################################################################

# bats test_tags=terminator::dircolors,terminator::dircolors::__enable__
@test "terminator::dircolors::__enable__ function-exists" {
  run type -t terminator::dircolors::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::dircolors,terminator::dircolors::__enable__
@test "terminator::dircolors::__enable__ when-dircolors-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::dircolors::__enable__

  # Returns early with failure when dircolors not found
  assert_failure
}

# bats test_tags=terminator::dircolors,terminator::dircolors::__enable__
@test "terminator::dircolors::__enable__ when-dircolors-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create minimal .dir_colors file
  echo "# dir_colors stub" >"${tmp_dir}/.dir_colors"

  # Create stub dircolors that outputs valid shell code
  cat >"${tmp_dir}/dircolors" <<'STUB'
#!/bin/sh
echo "LS_COLORS='rs=0:di=01;34'; export LS_COLORS;"
STUB
  chmod +x "${tmp_dir}/dircolors"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  HOME="${tmp_dir}" PATH="${tmp_dir}:${PATH}"
  run terminator::dircolors::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}

################################################################################
# terminator::dircolors::__disable__
################################################################################

# bats test_tags=terminator::dircolors,terminator::dircolors::__disable__
@test "terminator::dircolors::__disable__ function-exists" {
  run type -t terminator::dircolors::__disable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::dircolors,terminator::dircolors::__disable__
@test "terminator::dircolors::__disable__ unsets-LS_COLORS" {
  LS_COLORS='test'

  terminator::dircolors::__disable__

  [[ -z "${LS_COLORS+x}" ]]
}
