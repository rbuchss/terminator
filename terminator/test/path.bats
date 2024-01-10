#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/path.sh'

################################################################################
# terminator::path::__prepend__ general error cases
################################################################################

@test "terminator::path::__prepend__ invalid with-unknown-flag" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__prepend__ \
    --unknown \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__prepend__ invalid with-many-outputs" {
  local actual_1 \
    actual_2 \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__prepend__ \
    --output actual_1 \
    --output actual_2 \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__prepend__ invalid with-many-paths" {
  local actual \
    expected='' \
    dummy_path_1 \
    dummy_path_2 \
    elements=()

  run terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path_1}" \
    --path "${dummy_path_2}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__prepend__ invalid with-help-flag" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__prepend__ \
    --help \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

################################################################################
# terminator::path::__prepend__ with-output
################################################################################

@test "terminator::path::__prepend__ with-output unset-path empty-new-elements" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output empty-path empty-new-elements" {
  local actual \
    expected='' \
    dummy_path='' \
    elements=()

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output one-element-path empty-new-elements" {
  local actual \
    expected='/bin' \
    dummy_path='/bin' \
    elements=()

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output many-element-path empty-new-elements" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=()

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output unset-path one-new-element" {
  local actual \
    expected='/usr/local/bin' \
    dummy_path \
    elements=(/usr/local/bin)

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output empty-path one-new-element" {
  local actual \
    expected='/usr/local/bin' \
    dummy_path='' \
    elements=(/usr/local/bin)

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output one-element-path one-new-element" {
  local actual \
    expected='/usr/local/bin:/bin' \
    dummy_path='/bin' \
    elements=(/usr/local/bin)

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output many-element-path one-new-element" {
  local actual \
    expected='/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(/usr/local/bin)

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output unset-path many-new-elements" {
  local actual \
    expected='/opt/bin:~/.local/bin:/usr/local/bin' \
    dummy_path \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output empty-path many-new-elements" {
  local actual \
    expected='/opt/bin:~/.local/bin:/usr/local/bin' \
    dummy_path='' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output one-element-path many-new-elements" {
  local actual \
    expected='/opt/bin:~/.local/bin:/usr/local/bin:/bin' \
    dummy_path='/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output many-element-path many-new-elements" {
  local actual \
    expected='/opt/bin:~/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output path-already-contains-new-elements" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    ) \
    _status=0

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}" \
    || _status="$?"

  assert_exit_status 4 "${_status}"
  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output new-elements-contain-duplicates" {
  local actual \
    expected='/opt/bin:~/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    ) \
    _status=0

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}" \
    || _status="$?"

  assert_exit_status 3 "${_status}"
  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output path-already-contains-new-elements force-add" {
  local actual \
    expected='/sbin:/usr/sbin:/bin:/usr/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    )

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__prepend__ with-output new-elements-contain-duplicates force-add" {
  local actual \
    expected='~/.local/bin:/opt/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    )

  terminator::path::__prepend__ \
    --output actual \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

################################################################################
# terminator::path::__prepend__ without-output
################################################################################

@test "terminator::path::__prepend__ without-output unset-path empty-new-elements" {
  local expected='' \
    dummy_path \
    elements=()

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output empty-path empty-new-elements" {
  local expected='' \
    dummy_path='' \
    elements=()

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output one-element-path empty-new-elements" {
  local expected='/bin' \
    dummy_path='/bin' \
    elements=()

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output many-element-path empty-new-elements" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=()

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output unset-path one-new-element" {
  local expected='/usr/local/bin' \
    dummy_path \
    elements=(/usr/local/bin)

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output empty-path one-new-element" {
  local expected='/usr/local/bin' \
    dummy_path='' \
    elements=(/usr/local/bin)

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output one-element-path one-new-element" {
  local expected='/usr/local/bin:/bin' \
    dummy_path='/bin' \
    elements=(/usr/local/bin)

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output many-element-path one-new-element" {
  local expected='/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(/usr/local/bin)

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output unset-path many-new-elements" {
  local expected='/opt/bin:~/.local/bin:/usr/local/bin' \
    dummy_path \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output empty-path many-new-elements" {
  local expected='/opt/bin:~/.local/bin:/usr/local/bin' \
    dummy_path='' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output one-element-path many-new-elements" {
  local expected='/opt/bin:~/.local/bin:/usr/local/bin:/bin' \
    dummy_path='/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output many-element-path many-new-elements" {
  local expected='/opt/bin:~/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output path-already-contains-new-elements" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 4
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output new-elements-contain-duplicates" {
  local expected='/opt/bin:~/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 3
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output path-already-contains-new-elements force-add" {
  local expected='/sbin:/usr/sbin:/bin:/usr/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__prepend__ without-output new-elements-contain-duplicates force-add" {
  local expected='~/.local/bin:/opt/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    )

  run terminator::path::__prepend__ \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

################################################################################
# terminator::path::__append__ general error cases
################################################################################

@test "terminator::path::__append__ invalid with-unknown-flag" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__append__ \
    --unknown \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__append__ invalid with-many-outputs" {
  local actual_1 \
    actual_2 \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__append__ \
    --output actual_1 \
    --output actual_2 \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__append__ invalid with-many-paths" {
  local actual \
    expected='' \
    dummy_path_1 \
    dummy_path_2 \
    elements=()

  run terminator::path::__append__ \
    --output actual \
    --path "${dummy_path_1}" \
    --path "${dummy_path_2}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__append__ invalid with-help-flag" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__append__ \
    --help \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

################################################################################
# terminator::path::__append__ with-output
################################################################################

@test "terminator::path::__append__ with-output unset-path empty-new-elements" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output empty-path empty-new-elements" {
  local actual \
    expected='' \
    dummy_path='' \
    elements=()

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output one-element-path empty-new-elements" {
  local actual \
    expected='/bin' \
    dummy_path='/bin' \
    elements=()

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output many-element-path empty-new-elements" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=()

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output unset-path one-new-element" {
  local actual \
    expected='/usr/local/bin' \
    dummy_path \
    elements=(/usr/local/bin)

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output empty-path one-new-element" {
  local actual \
    expected='/usr/local/bin' \
    dummy_path='' \
    elements=(/usr/local/bin)

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output one-element-path one-new-element" {
  local actual \
    expected='/bin:/usr/local/bin' \
    dummy_path='/bin' \
    elements=(/usr/local/bin)

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output many-element-path one-new-element" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(/usr/local/bin)

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output unset-path many-new-elements" {
  local actual \
    expected='/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output empty-path many-new-elements" {
  local actual \
    expected='/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output one-element-path many-new-elements" {
  local actual \
    expected='/bin:/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output many-element-path many-new-elements" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output path-already-contains-new-elements" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    ) \
    _status=0

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}" \
    || _status="$?"

  assert_exit_status 4 "${_status}"
  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output new-elements-contain-duplicates" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    ) \
    _status=0

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}" \
    || _status="$?"

  assert_exit_status 3 "${_status}"
  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output path-already-contains-new-elements force-add" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    )

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__append__ with-output new-elements-contain-duplicates force-add" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/bin:~/.local/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    )

  terminator::path::__append__ \
    --output actual \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

################################################################################
# terminator::path::__append__ without-output
################################################################################

@test "terminator::path::__append__ without-output unset-path empty-new-elements" {
  local expected='' \
    dummy_path \
    elements=()

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output empty-path empty-new-elements" {
  local expected='' \
    dummy_path='' \
    elements=()

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output one-element-path empty-new-elements" {
  local expected='/bin' \
    dummy_path='/bin' \
    elements=()

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output many-element-path empty-new-elements" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=()

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output unset-path one-new-element" {
  local expected='/usr/local/bin' \
    dummy_path \
    elements=(/usr/local/bin)

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output empty-path one-new-element" {
  local expected='/usr/local/bin' \
    dummy_path='' \
    elements=(/usr/local/bin)

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output one-element-path one-new-element" {
  local expected='/bin:/usr/local/bin' \
    dummy_path='/bin' \
    elements=(/usr/local/bin)

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output many-element-path one-new-element" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(/usr/local/bin)

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output unset-path many-new-elements" {
  local expected='/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output empty-path many-new-elements" {
  local expected='/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output one-element-path many-new-elements" {
  local expected='/bin:/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output many-element-path many-new-elements" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output path-already-contains-new-elements" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 4
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output new-elements-contain-duplicates" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 3
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output path-already-contains-new-elements force-add" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/bin'
      '/bin'
      '/usr/sbin'
      '/sbin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__append__ without-output new-elements-contain-duplicates force-add" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/bin:~/.local/bin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
      '~/.local/bin'
    )

  run terminator::path::__append__ \
    --path "${dummy_path}" \
    --force \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

################################################################################
# terminator::path::__remove__ general error cases
################################################################################

@test "terminator::path::__remove__ invalid with-unknown-flag" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__remove__ \
    --unknown \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__remove__ invalid with-many-outputs" {
  local actual_1 \
    actual_2 \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__remove__ \
    --output actual_1 \
    --output actual_2 \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__remove__ invalid with-many-paths" {
  local actual \
    expected='' \
    dummy_path_1 \
    dummy_path_2 \
    elements=()

  run terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path_1}" \
    --path "${dummy_path_2}" \
    "${elements[@]}"

  assert_exit_status 255
}

@test "terminator::path::__remove__ invalid with-help-flag" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  run terminator::path::__remove__ \
    --help \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_exit_status 255
}

################################################################################
# terminator::path::__remove__ with-output
################################################################################

@test "terminator::path::__remove__ with-output unset-path empty-elements-to-remove" {
  local actual \
    expected='' \
    dummy_path \
    elements=()

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output empty-path empty-elements-to-remove" {
  local actual \
    expected='' \
    dummy_path='' \
    elements=()

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output one-element-path empty-elements-to-remove" {
  local actual \
    expected='/bin' \
    dummy_path='/bin' \
    elements=()

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output many-element-path empty-elements-to-remove" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=()

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output unset-path one-element-to-remove" {
  local actual \
    expected='' \
    dummy_path \
    elements=(/usr/local/bin)

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output empty-path one-element-to-remove" {
  local actual \
    expected='' \
    dummy_path='' \
    elements=(/usr/local/bin)

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output one-element-path one-element-to-remove" {
  local actual \
    expected='' \
    dummy_path='/bin' \
    elements=(/bin)

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output many-element-path one-element-to-remove" {
  local actual \
    expected='/usr/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(/bin)

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output unset-path many-elements-to-remove" {
  local actual \
    expected='' \
    dummy_path \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output empty-path many-elements-to-remove" {
  local actual \
    expected='' \
    dummy_path='' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output one-element-path many-elements-to-remove" {
  local actual \
    expected='' \
    dummy_path='/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/bin'
    )

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output many-element-path many-elements-to-remove" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output path-does-not-contains-remove-elements" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

@test "terminator::path::__remove__ with-output elements-to-remove-contain-duplicates" {
  local actual \
    expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  terminator::path::__remove__ \
    --output actual \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_equal "${expected}" "${actual}"
}

################################################################################
# terminator::path::__remove__ without-output
################################################################################

@test "terminator::path::__remove__ without-output unset-path empty-elements-to-remove" {
  local expected='' \
    dummy_path \
    elements=()

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output empty-path empty-elements-to-remove" {
  local expected='' \
    dummy_path='' \
    elements=()

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output one-element-path empty-elements-to-remove" {
  local expected='/bin' \
    dummy_path='/bin' \
    elements=()

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output many-element-path empty-elements-to-remove" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=()

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output unset-path one-element-to-remove" {
  local expected='' \
    dummy_path \
    elements=(/usr/local/bin)

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output empty-path one-element-to-remove" {
  local expected='' \
    dummy_path='' \
    elements=(/usr/local/bin)

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output one-element-path one-element-to-remove" {
  local expected='' \
    dummy_path='/bin' \
    elements=(/bin)

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output many-element-path one-element-to-remove" {
  local expected='/usr/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(/bin)

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output unset-path many-elements-to-remove" {
  local expected='' \
    dummy_path \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output empty-path many-elements-to-remove" {
  local expected='' \
    dummy_path='' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output one-element-path many-elements-to-remove" {
  local expected='' \
    dummy_path='/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/bin'
    )

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output many-element-path many-elements-to-remove" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output path-does-not-contains-remove-elements" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    elements=(
      '/usr/local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

@test "terminator::path::__remove__ without-output elements-to-remove-contain-duplicates" {
  local expected='/usr/bin:/bin:/usr/sbin:/sbin' \
    dummy_path='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:~/.local/bin:/opt/bin' \
    elements=(
      '/usr/local/bin'
      '/usr/local/bin'
      '~/.local/bin'
      '~/.local/bin'
      '/opt/bin'
    )

  run terminator::path::__remove__ \
    --path "${dummy_path}" \
    "${elements[@]}"

  assert_success
  assert_output "${expected}"
}

################################################################################
# terminator::path::__includes__
################################################################################

@test "terminator::path::__includes__ unset-path empty-element-to-search" {
  local dummy_path \
    element=''

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ empty-path empty-element-to-search" {
  local dummy_path='' \
    element=''

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ one-element-path empty-element-to-search" {
  local dummy_path='/bin' \
    element=''

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ many-element-path empty-element-to-search" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element=''

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ unset-path" {
  local dummy_path \
    element='/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ empty-path" {
  local dummy_path='' \
    element='/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ one-element-path" {
  local dummy_path='/bin' \
    element='/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__includes__ one-element-path missing-element-to-search" {
  local dummy_path='/sbin' \
    element='/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ many-element-path" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__includes__ many-element-path missing-element-to-search" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/usr/local/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__includes__ many-element-path element-to-search-on-far-left" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/usr/bin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__includes__ many-element-path element-to-search-on-far-right" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/sbin'

  run terminator::path::__includes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

################################################################################
# terminator::path::__excludes__
################################################################################

@test "terminator::path::__excludes__ unset-path empty-element-to-search" {
  local dummy_path \
    element=''

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ empty-path empty-element-to-search" {
  local dummy_path='' \
    element=''

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ one-element-path empty-element-to-search" {
  local dummy_path='/bin' \
    element=''

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ many-element-path empty-element-to-search" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element=''

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ unset-path" {
  local dummy_path \
    element='/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ empty-path" {
  local dummy_path='' \
    element='/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ one-element-path" {
  local dummy_path='/bin' \
    element='/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__excludes__ one-element-path missing-element-to-search" {
  local dummy_path='/sbin' \
    element='/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ many-element-path" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__excludes__ many-element-path missing-element-to-search" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/usr/local/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_success
  assert_no_output_exists
}

@test "terminator::path::__excludes__ many-element-path element-to-search-on-far-left" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/usr/bin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}

@test "terminator::path::__excludes__ many-element-path element-to-search-on-far-right" {
  local dummy_path='/usr/bin:/bin:/usr/sbin:/sbin' \
    element='/sbin'

  run terminator::path::__excludes__ "${dummy_path}" "${element}"
  assert_failure
  assert_no_output_exists
}
