#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/number.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::number::compare
################################################################################

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare" {
  run terminator::number::compare
  assert_failure 4
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 0" {
  run terminator::number::compare 0
  assert_failure 4
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 1 1" {
  run terminator::number::compare 1 1
  assert_success
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare -1 1" {
  run terminator::number::compare -1 1
  assert_failure 2
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare -2 -1" {
  run terminator::number::compare -2 -1
  assert_failure 2
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 1 1.1" {
  run terminator::number::compare 1 1.1
  assert_failure 2
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 1.1 1.10" {
  run terminator::number::compare 1.1 1.10
  assert_success
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 1.1 1.0" {
  run terminator::number::compare 1.1 1.0
  assert_failure 1
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 5.65 3.14e-22" {
  run terminator::number::compare 5.65 3.14e-22
  assert_failure 1
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 5.65e-23 3.14e-22" {
  run terminator::number::compare 5.65e-23 3.14e-22
  assert_failure 2
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 3.145678 3.145679" {
  run terminator::number::compare 3.145678 3.145679
  assert_failure 2
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 0xDEADBEEF 0xDEADBEF0" {
  run terminator::number::compare 0xDEADBEEF 0xDEADBEF0
  assert_failure 2
}

# bats test_tags=terminator::number,terminator::number::compare
@test "terminator::number::compare 0xDEADBEEF 0xDEADBEEE" {
  run terminator::number::compare 0xDEADBEEF 0xDEADBEEE
  assert_failure 1
}

################################################################################
# terminator::number::is_integer
################################################################################

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer no-args" {
  run --separate-stderr terminator::number::is_integer

  assert_failure 1
  refute_output
  assert_stderr
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer positive" {
  run terminator::number::is_integer '42'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer negative" {
  run terminator::number::is_integer '-42'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer with-plus" {
  run terminator::number::is_integer '+42'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer zero" {
  run terminator::number::is_integer '0'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer not-integer" {
  run terminator::number::is_integer 'abc'

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer float" {
  run terminator::number::is_integer '1.5'

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer empty-string" {
  run terminator::number::is_integer ''

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer multiple-valid" {
  run terminator::number::is_integer '1' '2' '-3' '+4'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_integer
@test "terminator::number::is_integer multiple-one-invalid" {
  run terminator::number::is_integer '1' 'abc' '3'

  assert_failure
}

################################################################################
# terminator::number::is_unsigned_integer
################################################################################

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer no-args" {
  run --separate-stderr terminator::number::is_unsigned_integer

  assert_failure 1
  refute_output
  assert_stderr
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer positive" {
  run terminator::number::is_unsigned_integer '42'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer with-plus" {
  run terminator::number::is_unsigned_integer '+42'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer zero" {
  run terminator::number::is_unsigned_integer '0'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer negative" {
  run terminator::number::is_unsigned_integer '-42'

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer not-integer" {
  run terminator::number::is_unsigned_integer 'abc'

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer float" {
  run terminator::number::is_unsigned_integer '1.5'

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer empty-string" {
  run terminator::number::is_unsigned_integer ''

  assert_failure
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer multiple-valid" {
  run terminator::number::is_unsigned_integer '1' '2' '+3' '0'

  assert_success
}

# bats test_tags=terminator::number,terminator::number::is_unsigned_integer
@test "terminator::number::is_unsigned_integer multiple-one-invalid" {
  run terminator::number::is_unsigned_integer '1' '-2' '3'

  assert_failure
}
