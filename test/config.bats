#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/config.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::config::path
################################################################################

# bats test_tags=terminator::config,terminator::config::path
@test "terminator::config::path" {
  run terminator::config::path
  assert_success
  assert_output "${TERMINATOR_CONFIG_DIR}"
}

# bats test_tags=terminator::config,terminator::config::path
@test "terminator::config::path '.bashrc' '${HOME}'" {
  run terminator::config::path ".bashrc" "${HOME}"
  assert_success
  assert_output "${HOME}/.bashrc"
}

# bats test_tags=terminator::config,terminator::config::path
@test "terminator::config::path '${HOME}/.bashrc'" {
  run terminator::config::path "${HOME}/.bashrc"
  assert_success
  assert_output "${HOME}/.bashrc"
}

# bats test_tags=terminator::config,terminator::config::path
@test "terminator::config::path '~/.bashrc'" {
  run terminator::config::path "~/.bashrc"
  assert_success
  assert_output "~/.bashrc"
}

# bats test_tags=terminator::config,terminator::config::path
@test "terminator::config::path os/darwin.sh" {
  run terminator::config::path 'os/darwin.sh'
  assert_success
  assert_output "${TERMINATOR_CONFIG_DIR}/os/darwin.sh"
}

# bats test_tags=terminator::config,terminator::config::path
@test "terminator::config::path os/darwin.sh config_dir_override" {
  run terminator::config::path 'os/darwin.sh' 'config_dir_override'
  assert_success
  assert_output "config_dir_override/os/darwin.sh"
}

################################################################################
# terminator::config::is_path_absolute
################################################################################

# bats test_tags=terminator::config,terminator::config::is_path_absolute
@test "terminator::config::is_path_absolute with-absolute-path" {
  run terminator::config::is_path_absolute '/usr/local/bin'

  assert_success
}

# bats test_tags=terminator::config,terminator::config::is_path_absolute
@test "terminator::config::is_path_absolute with-tilde-path" {
  run terminator::config::is_path_absolute '~/.bashrc'

  assert_success
}

# bats test_tags=terminator::config,terminator::config::is_path_absolute
@test "terminator::config::is_path_absolute with-relative-path" {
  run terminator::config::is_path_absolute 'relative/path'

  assert_failure
}

# bats test_tags=terminator::config,terminator::config::is_path_absolute
@test "terminator::config::is_path_absolute with-empty-path" {
  run terminator::config::is_path_absolute ''

  assert_failure
}

# bats test_tags=terminator::config,terminator::config::is_path_absolute
@test "terminator::config::is_path_absolute with-dot-path" {
  run terminator::config::is_path_absolute './relative'

  assert_failure
}

################################################################################
# terminator::config::cd
################################################################################

# bats test_tags=terminator::config,terminator::config::cd
@test "terminator::config::cd with-existing-directory" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  TERMINATOR_CONFIG_DIR="${temp_dir}"
  terminator::config::cd
  local actual_pwd
  actual_pwd="$(pwd)"

  assert_equal "${actual_pwd}" "${temp_dir}"

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::config,terminator::config::cd
@test "terminator::config::cd with-argument" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  terminator::config::cd "${temp_dir}"
  local actual_pwd
  actual_pwd="$(pwd)"

  assert_equal "${actual_pwd}" "${temp_dir}"

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::config::load
################################################################################

# bats test_tags=terminator::config,terminator::config::load
@test "terminator::config::load with-valid-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_config_dir="${TERMINATOR_CONFIG_DIR}"
  TERMINATOR_CONFIG_DIR="${temp_dir}"

  echo 'TEST_CONFIG_LOADED=1' >"${temp_dir}/test.sh"

  terminator::config::load 'test.sh'

  TERMINATOR_CONFIG_DIR="${original_config_dir}"

  assert_equal "${TEST_CONFIG_LOADED}" '1'

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::config::hooks::invoke
################################################################################

# bats test_tags=terminator::config,terminator::config::hooks::invoke
@test "terminator::config::hooks::invoke no-hook-type" {
  run --separate-stderr terminator::config::hooks::invoke

  assert_failure 1
}

# bats test_tags=terminator::config,terminator::config::hooks::invoke
@test "terminator::config::hooks::invoke with-empty-hook-dir" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/before"

  run terminator::config::hooks::invoke 'before' "${temp_dir}"

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::config,terminator::config::hooks::invoke
@test "terminator::config::hooks::invoke with-hook-files" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/before"

  echo 'HOOK_BEFORE_EXECUTED=1' >"${temp_dir}/before/01-test.sh"

  terminator::config::hooks::invoke 'before' "${temp_dir}"

  assert_equal "${HOOK_BEFORE_EXECUTED}" '1'

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::config::hooks::before
################################################################################

# bats test_tags=terminator::config,terminator::config::hooks::before
@test "terminator::config::hooks::before with-empty-dir" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_hooks_dir="${TERMINATOR_HOOKS_DIR}"
  TERMINATOR_HOOKS_DIR="${temp_dir}"
  mkdir -p "${temp_dir}/before"

  run terminator::config::hooks::before

  TERMINATOR_HOOKS_DIR="${original_hooks_dir}"

  assert_success

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::config::hooks::after
################################################################################

# bats test_tags=terminator::config,terminator::config::hooks::after
@test "terminator::config::hooks::after with-empty-dir" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_hooks_dir="${TERMINATOR_HOOKS_DIR}"
  TERMINATOR_HOOKS_DIR="${temp_dir}"
  mkdir -p "${temp_dir}/after"

  run terminator::config::hooks::after

  TERMINATOR_HOOKS_DIR="${original_hooks_dir}"

  assert_success

  rm -rf "${temp_dir}"
}
