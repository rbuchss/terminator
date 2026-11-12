#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/slack.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::slack::theme
################################################################################

# bats test_tags=terminator::slack,terminator::slack::theme
@test "terminator::slack::theme prints-the-frankenstein-theme-string" {
  run terminator::slack::theme

  assert_success
  assert_output '#2A302C,#59665D,#8FBF6A,#2A302C,#3A433D,#E4E8E1,#8FBF6A,#B7D98A'
}

# bats test_tags=terminator::slack,terminator::slack::theme
@test "terminator::slack::theme prints-eight-comma-separated-hex-fields" {
  local \
    field \
    fields

  run terminator::slack::theme
  assert_success

  # Slack custom themes are eight comma-separated #RRGGBB fields in a fixed
  # order, so a hand edit of the literal that breaks the shape fails here.
  IFS=',' read -r -a fields <<<"${lines[0]}"

  assert_equal "${#fields[@]}" 8

  for field in "${fields[@]}"; do
    if ! [[ "${field}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
      fail "field '${field}' is not a #RRGGBB hex value"
    fi
  done
}

################################################################################
# terminator::slack::__enable__
################################################################################

# bats test_tags=terminator::slack,terminator::slack::__enable__
@test "terminator::slack::__enable__ defines-the-slack-theme-alias" {
  terminator::slack::__enable__

  # `type -t` cannot see aliases in this non-interactive shell (it skips
  # them unless expand_aliases is on), so assert through the alias builtin,
  # which reads the alias table directly.
  run alias slack-theme

  assert_success
  assert_output "alias slack-theme='terminator::slack::theme'"
}

################################################################################
# terminator::slack::__disable__
################################################################################

# bats test_tags=terminator::slack,terminator::slack::__disable__
@test "terminator::slack::__disable__ removes-the-slack-theme-alias" {
  terminator::slack::__enable__

  run alias slack-theme
  assert_success

  terminator::slack::__disable__

  run alias slack-theme

  assert_failure
}

# bats test_tags=terminator::slack,terminator::slack::__disable__
@test "terminator::slack::__disable__ tolerates-a-missing-alias" {
  run terminator::slack::__disable__

  assert_success
}

################################################################################
# Function existence sweep
################################################################################

# bats test_tags=terminator::slack,terminator::slack::functions
@test "terminator::slack defines all public and lifecycle functions" {
  local fn
  for fn in \
    terminator::slack::theme \
    terminator::slack::__enable__ \
    terminator::slack::__disable__ \
    terminator::slack::__export__ \
    terminator::slack::__recall__; do
    declare -F "${fn}" >/dev/null || {
      echo "missing function: ${fn}"
      return 1
    }
  done
}
