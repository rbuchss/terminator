#!/usr/bin/env bats

load test_helper

source "$(repo_root)/terminator/src/ssh.sh"

@test "terminator::ssh::is_ssh_session" {
  run terminator::ssh::is_ssh_session
  assert_failure
}

@test "terminator::ssh::is_ssh_session SSH_CLIENT='1.1.1.1 123 22'" {
  SSH_CLIENT='1.1.1.1 123 22'
  run terminator::ssh::is_ssh_session
  assert_success
}

@test "terminator::ssh::is_ssh_session SSH_TTY='/dev/ttys123'" {
  SSH_CLIENT='/dev/ttys123'
  run terminator::ssh::is_ssh_session
  assert_success
}
