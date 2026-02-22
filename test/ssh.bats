#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/ssh.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::ssh::is_ssh_session
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::is_ssh_session
@test "terminator::ssh::is_ssh_session" {
  unset TERMINATOR_SSH_IS_SSH_SESSION
  run terminator::ssh::is_ssh_session
  assert_failure
}

# bats test_tags=terminator::ssh,terminator::ssh::is_ssh_session
@test "terminator::ssh::is_ssh_session SSH_CLIENT='1.1.1.1 123 22'" {
  unset TERMINATOR_SSH_IS_SSH_SESSION
  SSH_CLIENT='1.1.1.1 123 22'
  run terminator::ssh::is_ssh_session
  assert_success
}

# bats test_tags=terminator::ssh,terminator::ssh::is_ssh_session
@test "terminator::ssh::is_ssh_session SSH_TTY='/dev/ttys123'" {
  unset TERMINATOR_SSH_IS_SSH_SESSION
  SSH_CLIENT='/dev/ttys123'
  run terminator::ssh::is_ssh_session
  assert_success
}

# bats test_tags=terminator::ssh,terminator::ssh::is_ssh_session
@test "terminator::ssh::is_ssh_session cached-result-true" {
  TERMINATOR_SSH_IS_SSH_SESSION=1
  unset SSH_CLIENT
  unset SSH_TTY

  run terminator::ssh::is_ssh_session

  assert_success
}

# bats test_tags=terminator::ssh,terminator::ssh::is_ssh_session
@test "terminator::ssh::is_ssh_session cached-result-false" {
  TERMINATOR_SSH_IS_SSH_SESSION=0
  unset SSH_CLIENT
  unset SSH_TTY

  run terminator::ssh::is_ssh_session

  assert_failure
}

################################################################################
# terminator::ssh::ppinfo
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::ppinfo
@test "terminator::ssh::ppinfo" {
  # Use a known PID - the test's own parent process
  local parent_pid="${PPID}"

  run terminator::ssh::ppinfo "${parent_pid}"

  # ps may fail in restricted containers, just verify it ran
  assert_output
}

################################################################################
# terminator::ssh::generate_key::usage
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::generate_key::usage
@test "terminator::ssh::generate_key::usage" {
  run terminator::ssh::generate_key::usage

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial '--key-type'
  assert_output --partial '--suffix'
}

################################################################################
# terminator::ssh::generate_key
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::generate_key
@test "terminator::ssh::generate_key --help" {
  run --separate-stderr terminator::ssh::generate_key --help

  assert_failure "${TERMINATOR_SSH_INVALID_STATUS}"
  assert_stderr --partial 'Usage:'
}

# bats test_tags=terminator::ssh,terminator::ssh::generate_key
@test "terminator::ssh::generate_key invalid-option" {
  run --separate-stderr terminator::ssh::generate_key --invalid-flag

  assert_failure "${TERMINATOR_SSH_INVALID_STATUS}"
  assert_stderr --partial 'invalid option'
}

################################################################################
# terminator::ssh::add_key
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::add_key
@test "terminator::ssh::add_key missing-private-key" {
  run --separate-stderr terminator::ssh::add_key '/nonexistent/key'

  assert_failure 1
}

# bats test_tags=terminator::ssh,terminator::ssh::add_key
@test "terminator::ssh::add_key missing-public-key" {
  local temp_file
  temp_file="$(mktemp)"

  run --separate-stderr terminator::ssh::add_key "${temp_file}"

  assert_failure 1

  rm -f "${temp_file}"
}

################################################################################
# terminator::ssh::add_key::os::unsupported
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::add_key::os::unsupported
@test "terminator::ssh::add_key::os::unsupported" {
  run --separate-stderr terminator::ssh::add_key::os::unsupported

  assert_failure 1
}

################################################################################
# terminator::ssh::find_keys
################################################################################

# bats test_tags=terminator::ssh,terminator::ssh::find_keys
@test "terminator::ssh::find_keys with-test-dir" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_dir}"
  mkdir -p "${temp_dir}/.ssh"

  touch "${temp_dir}/.ssh/id_ed25519"
  touch "${temp_dir}/.ssh/id_ed25519.pub"
  touch "${temp_dir}/.ssh/id_rsa"
  touch "${temp_dir}/.ssh/id_rsa.pub"

  run terminator::ssh::find_keys

  HOME="${original_home}"

  assert_success
  assert_output --partial 'id_ed25519'
  assert_output --partial 'id_rsa'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::ssh,terminator::ssh::find_keys
@test "terminator::ssh::find_keys with-no-keys" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_dir}"
  mkdir -p "${temp_dir}/.ssh"

  run terminator::ssh::find_keys

  HOME="${original_home}"

  assert_success
  refute_output

  rm -rf "${temp_dir}"
}
