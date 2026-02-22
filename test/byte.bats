#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/byte.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::byte::reverse_endianness
################################################################################

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness no-args" {
  run --separate-stderr terminator::byte::reverse_endianness

  assert_failure 1
  refute_output
  assert_stderr
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness too-many-args" {
  run --separate-stderr terminator::byte::reverse_endianness 'AABB' 'CCDD'

  assert_failure 1
  refute_output
  assert_stderr
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness AABB" {
  run terminator::byte::reverse_endianness 'AABB'

  assert_success
  assert_output 'BBAA'
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness AABBCCDD" {
  run terminator::byte::reverse_endianness 'AABBCCDD'

  assert_success
  assert_output 'DDCCBBAA'
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness DEADBEEF" {
  run terminator::byte::reverse_endianness 'DEADBEEF'

  assert_success
  assert_output 'EFBEADDE'
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness 0123456789ABCDEF" {
  run terminator::byte::reverse_endianness '0123456789ABCDEF'

  assert_success
  assert_output 'EFCDAB8967452301'
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness single-byte" {
  run terminator::byte::reverse_endianness 'FF'

  assert_success
  assert_output 'FF'
}

# bats test_tags=terminator::byte,terminator::byte::reverse_endianness
@test "terminator::byte::reverse_endianness empty-string" {
  run terminator::byte::reverse_endianness ''

  assert_success
  assert_output ''
}
