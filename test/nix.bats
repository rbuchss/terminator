#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/nix.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::nix::__profiles__
################################################################################

# bats test_tags=terminator::nix,terminator::nix::__profiles__
@test "terminator::nix::__profiles__ prints-nix-profiles-entries-in-order" {
  NIX_PROFILES='/nix/var/nix/profiles/default /home/user/.nix-profile'

  run terminator::nix::__profiles__

  assert_success
  assert_line -n 0 '/nix/var/nix/profiles/default'
  assert_line -n 1 '/home/user/.nix-profile'
}

# bats test_tags=terminator::nix,terminator::nix::__profiles__
@test "terminator::nix::__profiles__ falls-back-to-standard-locations" {
  unset NIX_PROFILES

  run terminator::nix::__profiles__

  assert_success
  assert_line -n 0 '/nix/var/nix/profiles/default'
  assert_line -n 1 "${HOME}/.nix-profile"
}

# bats test_tags=terminator::nix,terminator::nix::__profiles__
@test "terminator::nix::__profiles__ handles-single-entry" {
  NIX_PROFILES='/custom/profile'

  run terminator::nix::__profiles__

  assert_success
  assert_output '/custom/profile'
}

# bats test_tags=terminator::nix,terminator::nix::__profiles__
@test "terminator::nix::__profiles__ falls-back-to-standard-locations-when-set-to-empty" {
  NIX_PROFILES=''

  run terminator::nix::__profiles__

  assert_success
  assert_line -n 0 '/nix/var/nix/profiles/default'
  assert_line -n 1 "${HOME}/.nix-profile"
}

# bats test_tags=terminator::nix,terminator::nix::__profiles__
@test "terminator::nix::__profiles__ collapses-repeated-separators" {
  NIX_PROFILES='/custom/one   /custom/two'

  run terminator::nix::__profiles__

  assert_success
  assert_line -n 0 '/custom/one'
  assert_line -n 1 '/custom/two'
}

# bats test_tags=terminator::nix,terminator::nix::__profiles__
@test "terminator::nix::__profiles__ prints-nothing-for-blank-value" {
  NIX_PROFILES='   '

  run terminator::nix::__profiles__

  assert_success
  assert_output ''
}

################################################################################
# terminator::nix::__enable__
################################################################################

# bats test_tags=terminator::nix,terminator::nix::__enable__
@test "terminator::nix::__enable__ function-exists" {
  run type -t terminator::nix::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::nix,terminator::nix::__enable__
@test "terminator::nix::__enable__ when-nix-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  unset NIX_PROFILES

  run terminator::nix::__enable__

  assert_failure
}

# bats test_tags=terminator::nix,terminator::nix::__enable__
@test "terminator::nix::__enable__ when-nix-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  unset NIX_PROFILES

  run terminator::nix::__enable__

  assert_success
}

# bats test_tags=terminator::nix,terminator::nix::__enable__
@test "terminator::nix::__enable__ prepends-existing-profile-bins" {
  local \
    temp_root \
    original_path="${PATH}"

  temp_root="$(mktemp -d)"
  mkdir -p "${temp_root}/default/bin" "${temp_root}/user/bin"
  NIX_PROFILES="${temp_root}/default ${temp_root}/user"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # `run` isolates PATH mutations, so call directly and restore it after.
  terminator::nix::__enable__

  # NIX_PROFILES lists the user profile last (highest priority), so prepending
  # in that order leaves it first on PATH, ahead of the default profile.
  assert_equal \
    "${PATH}" \
    "${temp_root}/user/bin:${temp_root}/default/bin:${original_path}"

  PATH="${original_path}"
  rm -rf "${temp_root}"
}

# bats test_tags=terminator::nix,terminator::nix::__enable__
@test "terminator::nix::__enable__ skips-missing-profile-bins" {
  local \
    temp_root \
    original_path="${PATH}"

  temp_root="$(mktemp -d)"
  NIX_PROFILES="${temp_root}/default ${temp_root}/user"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  terminator::nix::__enable__

  assert_equal "${PATH}" "${original_path}"

  rm -rf "${temp_root}"
}

################################################################################
# terminator::nix::__disable__
################################################################################

# bats test_tags=terminator::nix,terminator::nix::__disable__
@test "terminator::nix::__disable__ function-exists" {
  run type -t terminator::nix::__disable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::nix,terminator::nix::__disable__
@test "terminator::nix::__disable__ removes-profile-bins" {
  local \
    temp_root \
    original_path="${PATH}"

  temp_root="$(mktemp -d)"
  NIX_PROFILES="${temp_root}/default ${temp_root}/user"
  PATH="${temp_root}/user/bin:${temp_root}/default/bin:${PATH}"

  terminator::nix::__disable__

  assert_equal "${PATH}" "${original_path}"

  rm -rf "${temp_root}"
}
