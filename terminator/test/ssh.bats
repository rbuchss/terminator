#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/ssh.sh'

@test "terminator::ssh::is_ssh_session" {
  unset TERMINATOR_SSH_IS_SSH_SESSION
  run terminator::ssh::is_ssh_session
  assert_failure
}

@test "terminator::ssh::is_ssh_session SSH_CLIENT='1.1.1.1 123 22'" {
  unset TERMINATOR_SSH_IS_SSH_SESSION
  SSH_CLIENT='1.1.1.1 123 22'
  run terminator::ssh::is_ssh_session
  assert_success
}

@test "terminator::ssh::is_ssh_session SSH_TTY='/dev/ttys123'" {
  unset TERMINATOR_SSH_IS_SSH_SESSION
  SSH_CLIENT='/dev/ttys123'
  run terminator::ssh::is_ssh_session
  assert_success
}
