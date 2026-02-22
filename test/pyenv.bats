#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/pyenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::pyenv::__enable__
################################################################################

# bats test_tags=terminator::pyenv,terminator::pyenv::__enable__
@test "terminator::pyenv::__enable__ function-exists" {
  run type -t terminator::pyenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::pyenv,terminator::pyenv::__enable__
@test "terminator::pyenv::__enable__ when-pyenv-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::pyenv::__enable__

  assert_failure
}

# bats test_tags=terminator::pyenv,terminator::pyenv::__enable__
@test "terminator::pyenv::__enable__ when-pyenv-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create stub pyenv that outputs no-op shell code for both
  # 'pyenv init --path' and 'pyenv init -'
  cat >"${tmp_dir}/pyenv" <<'STUB'
#!/bin/sh
echo "# pyenv init stub"
STUB
  chmod +x "${tmp_dir}/pyenv"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # homebrew::package::is_installed returns false (no brew) — skips completion
  PATH="${tmp_dir}:${PATH}"
  run terminator::pyenv::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
