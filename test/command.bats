#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/command.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::command::exists general error cases
################################################################################

@test "terminator::command::exists invalid with-unknown-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::exists \
    --unknown \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

@test "terminator::command::exists invalid with-empty-arguments" {
  local arguments=()

  run --separate-stderr terminator::command::exists \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}


@test "terminator::command::exists invalid with-many-arguments" {
  local arguments=(ls cat)

  run --separate-stderr terminator::command::exists \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

@test "terminator::command::exists invalid with-help-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::exists \
    --help \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

################################################################################
# terminator::command::exists
################################################################################

@test "terminator::command::exists command-exists" {
  local arguments=('ls')

  run --separate-stderr terminator::command::exists \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::exists command-does-not-exist" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::exists \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::exists command-exists verbose-mode" {
  local arguments=('ls')

  run --separate-stderr terminator::command::exists \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::exists command-does-not-exist verbose-mode" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::exists \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::exists command-does-not-exist verbose-mode error-log-level" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::exists \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}

################################################################################
# terminator::command::any_exist general error cases
################################################################################

@test "terminator::command::any_exist invalid with-unknown-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::any_exist \
    --unknown \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

@test "terminator::command::any_exist invalid with-empty-arguments" {
  local arguments=()

  run --separate-stderr terminator::command::any_exist \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}


@test "terminator::command::any_exist invalid with-help-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::any_exist \
    --help \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

################################################################################
# terminator::command::any_exist
################################################################################

@test "terminator::command::any_exist single-command-exists" {
  local arguments=('ls')

  run --separate-stderr terminator::command::any_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist single-command-does-not-exist" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::any_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist single-command-exists verbose-mode" {
  local arguments=('ls')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist single-command-does-not-exist verbose-mode" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::any_exist single-command-does-not-exist verbose-mode error-log-level" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}

@test "terminator::command::any_exist multiple-commands-all-exist" {
  local arguments=('ls' 'cat')

  run --separate-stderr terminator::command::any_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist multiple-commands-one-exists" {
  local arguments=('ls' 'invalid-command')

  run --separate-stderr terminator::command::any_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist multiple-commands-all-do-not-exist" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::any_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist multiple-commands-all-exist verbose-mode" {
  local arguments=('ls' 'cat')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist multiple-commands-one-exists verbose-mode" {
  local arguments=('ls' 'invalid-command')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::any_exist multiple-commands-all-do-not-exist verbose-mode" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::any_exist multiple-commands-all-do-not-exist verbose-mode error-log-level" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::any_exist \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}

################################################################################
# terminator::command::none_exist general error cases
################################################################################

@test "terminator::command::none_exist invalid with-unknown-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::none_exist \
    --unknown \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

@test "terminator::command::none_exist invalid with-empty-arguments" {
  local arguments=()

  run --separate-stderr terminator::command::none_exist \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}


@test "terminator::command::none_exist invalid with-help-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::none_exist \
    --help \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

################################################################################
# terminator::command::none_exist
################################################################################

@test "terminator::command::none_exist single-command-exists" {
  local arguments=('ls')

  run --separate-stderr terminator::command::none_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist single-command-does-not-exist" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::none_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist single-command-exists verbose-mode" {
  local arguments=('ls')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::none_exist single-command-does-not-exist verbose-mode" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist single-command-exists verbose-mode error-log-level" {
  local arguments=('ls')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}

@test "terminator::command::none_exist multiple-commands-all-exist" {
  local arguments=('ls' 'cat')

  run --separate-stderr terminator::command::none_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist multiple-commands-one-exists" {
  local arguments=('ls' 'invalid-command')

  run --separate-stderr terminator::command::none_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist multiple-commands-all-do-not-exist" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::none_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist multiple-commands-all-exist verbose-mode" {
  local arguments=('ls' 'cat')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::none_exist multiple-commands-one-exists verbose-mode" {
  local arguments=('ls' 'invalid-command')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::none_exist multiple-commands-all-do-not-exist verbose-mode" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::none_exist multiple-commands-one-exists verbose-mode error-log-level" {
  local arguments=('ls' 'invalid-command-2')

  run --separate-stderr terminator::command::none_exist \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}

################################################################################
# terminator::command::all_exist general error cases
################################################################################

@test "terminator::command::all_exist invalid with-unknown-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::all_exist \
    --unknown \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

@test "terminator::command::all_exist invalid with-empty-arguments" {
  local arguments=()

  run --separate-stderr terminator::command::all_exist \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}


@test "terminator::command::all_exist invalid with-help-flag" {
  local arguments=('ls')

  run --separate-stderr terminator::command::all_exist \
    --help \
    "${arguments[@]}"

  assert_failure 255
  refute_output
  assert_stderr
}

################################################################################
# terminator::command::all_exist
################################################################################

@test "terminator::command::all_exist single-command-exists" {
  local arguments=('ls')

  run --separate-stderr terminator::command::all_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist single-command-does-not-exist" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::all_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist single-command-exists verbose-mode" {
  local arguments=('ls')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist single-command-does-not-exist verbose-mode" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::all_exist single-command-does-not-exist verbose-mode error-log-level" {
  local arguments=('invalid-command')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}

@test "terminator::command::all_exist multiple-commands-all-exist" {
  local arguments=('ls' 'cat')

  run --separate-stderr terminator::command::all_exist \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist multiple-commands-one-exists" {
  local arguments=('ls' 'invalid-command')

  run --separate-stderr terminator::command::all_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist multiple-commands-all-do-not-exist" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::all_exist \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist multiple-commands-all-exist verbose-mode" {
  local arguments=('ls' 'cat')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    "${arguments[@]}"

  assert_success
  refute_output
  refute_stderr
}

@test "terminator::command::all_exist multiple-commands-one-exists verbose-mode" {
  local arguments=('ls' 'invalid-command')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::all_exist multiple-commands-all-do-not-exist verbose-mode" {
  local arguments=('invalid-command-1' 'invalid-command-2')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'WARNING'
}

@test "terminator::command::all_exist multiple-commands-one-exists verbose-mode error-log-level" {
  local arguments=('ls' 'invalid-command-2')

  run --separate-stderr terminator::command::all_exist \
    --verbose \
    --log-level 'error' \
    "${arguments[@]}"

  assert_failure 1
  refute_output
  assert_stderr --regexp 'ERROR'
}
