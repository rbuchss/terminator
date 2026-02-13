#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/os.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::os::switch
################################################################################

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch --help" {
  run terminator::os::switch --help

  assert_success
  assert_output --partial 'Usage:'
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch invalid-option" {
  run --separate-stderr terminator::os::switch --invalid

  assert_failure 1
  refute_output
  assert_stderr --partial 'invalid option'
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch with-darwin-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='darwin23'

  run terminator::os::switch \
    --darwin echo \
    'darwin-was-called'

  OSTYPE="${original_ostype}"

  assert_success
  assert_output 'darwin-was-called'
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch with-linux-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='linux-gnu'

  run terminator::os::switch \
    --linux echo \
    'linux-was-called'

  OSTYPE="${original_ostype}"

  assert_success
  assert_output 'linux-was-called'
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch with-windows-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='msys'

  run terminator::os::switch \
    --windows echo \
    'windows-was-called'

  OSTYPE="${original_ostype}"

  assert_success
  assert_output 'windows-was-called'
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch with-unsupported-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='unknown-os'

  run terminator::os::switch \
    --unsupported echo \
    'unsupported-was-called'

  OSTYPE="${original_ostype}"

  assert_success
  assert_output 'unsupported-was-called'
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch default-darwin-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='darwin23'

  run --separate-stderr terminator::os::switch 'arg1' 'arg2'

  OSTYPE="${original_ostype}"

  assert_success
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch default-linux-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='linux-gnu'

  run --separate-stderr terminator::os::switch 'arg1'

  OSTYPE="${original_ostype}"

  assert_success
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch default-unsupported-handler" {
  local original_ostype="${OSTYPE}"
  OSTYPE='unknown-os'

  run --separate-stderr terminator::os::switch

  OSTYPE="${original_ostype}"

  assert_failure 1
}

# bats test_tags=terminator::os,terminator::os::switch
@test "terminator::os::switch passes-arguments-through" {
  local original_ostype="${OSTYPE}"
  OSTYPE='darwin23'

  run terminator::os::switch \
    --darwin echo \
    'arg1' 'arg2' 'arg3'

  OSTYPE="${original_ostype}"

  assert_success
  assert_output 'arg1 arg2 arg3'
}

################################################################################
# terminator::os::switch::usage
################################################################################

# bats test_tags=terminator::os,terminator::os::switch::usage
@test "terminator::os::switch::usage" {
  run terminator::os::switch::usage

  assert_success
  assert_output --partial '--darwin'
  assert_output --partial '--linux'
  assert_output --partial '--windows'
  assert_output --partial '--unsupported'
}
