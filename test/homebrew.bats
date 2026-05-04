#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/homebrew.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::homebrew::is_installed
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed when-brew-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::homebrew::is_installed

  assert_failure
}

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed when-brew-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::homebrew::is_installed

  assert_success
}

# bats test_tags=terminator::homebrew,terminator::homebrew::is_installed
@test "terminator::homebrew::is_installed direct-call" {
  local exit_status=0

  terminator::homebrew::is_installed || exit_status=$?

  # Just verify it runs without crashing
  [[ "${exit_status}" -eq 0 || "${exit_status}" -eq 1 ]]
}

################################################################################
# terminator::homebrew::package::is_installed
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::package::is_installed
@test "terminator::homebrew::package::is_installed when-brew-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::homebrew::package::is_installed 'nonexistent'

  assert_failure
}

# bats test_tags=terminator::homebrew,terminator::homebrew::package::is_installed
@test "terminator::homebrew::package::is_installed when-package-exists" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function brew { echo "${temp_dir}"; }

  run terminator::homebrew::package::is_installed 'some-package'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::homebrew,terminator::homebrew::package::is_installed
@test "terminator::homebrew::package::is_installed when-package-not-exists" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
  # shellcheck disable=SC2317 # invoked indirectly
  function brew { echo "/nonexistent/path"; }

  run terminator::homebrew::package::is_installed 'some-package'

  assert_failure
}

################################################################################
# terminator::homebrew::__enable__
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::__enable__
@test "terminator::homebrew::__enable__ when-no-brew-paths-exist" {
  run --separate-stderr terminator::homebrew::__enable__

  # Returns success (bare return) with warning logged
  assert_success
}

################################################################################
# terminator::homebrew
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::add_paths
@test "terminator::homebrew::add_paths function-exists" {
  run type -t terminator::homebrew::add_paths

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::clean
@test "terminator::homebrew::clean function-exists" {
  run type -t terminator::homebrew::clean

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::cask::clean
@test "terminator::homebrew::cask::clean function-exists" {
  run type -t terminator::homebrew::cask::clean

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::homebrew::__strip_nosort_option__
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ function-exists" {
  run type -t terminator::homebrew::__strip_nosort_option__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ drops-leading-nosort" {
  run terminator::homebrew::__strip_nosort_option__ -o nosort -F _foo bar

  assert_success
  assert_line --index 0 -- '-F'
  assert_line --index 1 '_foo'
  assert_line --index 2 'bar'
  ((${#lines[@]} == 3))
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ preserves-other-o-options" {
  run terminator::homebrew::__strip_nosort_option__ -o filenames -F _foo bar

  assert_success
  assert_line --index 0 -- '-o'
  assert_line --index 1 'filenames'
  assert_line --index 2 -- '-F'
  assert_line --index 3 '_foo'
  assert_line --index 4 'bar'
  ((${#lines[@]} == 5))
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ drops-only-nosort-when-mixed" {
  run terminator::homebrew::__strip_nosort_option__ -o nosort -o filenames -F _foo bar

  assert_success
  assert_line --index 0 -- '-o'
  assert_line --index 1 'filenames'
  assert_line --index 2 -- '-F'
  assert_line --index 3 '_foo'
  assert_line --index 4 'bar'
  ((${#lines[@]} == 5))
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ drops-trailing-nosort" {
  run terminator::homebrew::__strip_nosort_option__ -o nospace -o nosort -F _foo bar

  assert_success
  assert_line --index 0 -- '-o'
  assert_line --index 1 'nospace'
  assert_line --index 2 -- '-F'
  assert_line --index 3 '_foo'
  assert_line --index 4 'bar'
  ((${#lines[@]} == 5))
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ handles-only-nosort" {
  run terminator::homebrew::__strip_nosort_option__ -o nosort

  assert_success
  assert_output ''
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ passes-through-without-o-options" {
  run terminator::homebrew::__strip_nosort_option__ -F _foo bar

  assert_success
  assert_line --index 0 -- '-F'
  assert_line --index 1 '_foo'
  assert_line --index 2 'bar'
  ((${#lines[@]} == 3))
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ preserves-single-flag" {
  run terminator::homebrew::__strip_nosort_option__ -p

  assert_success
  assert_output -- '-p'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__strip_nosort_option__
@test "terminator::homebrew::__strip_nosort_option__ keeps-trailing-bare-o" {
  # `-o` at end of arglist with no following option: not our problem to
  # validate, just don't drop it. The real `complete` builtin will
  # reject it on its own.
  run terminator::homebrew::__strip_nosort_option__ -F _foo bar -o

  assert_success
  assert_line --index 0 -- '-F'
  assert_line --index 1 '_foo'
  assert_line --index 2 'bar'
  assert_line --index 3 -- '-o'
  ((${#lines[@]} == 4))
}

################################################################################
# terminator::homebrew::__enable__::complete_nosort_shim
################################################################################

# bats test_tags=terminator::homebrew,terminator::homebrew::__enable__::complete_nosort_shim
@test "terminator::homebrew::__enable__::complete_nosort_shim function-exists" {
  run type -t terminator::homebrew::__enable__::complete_nosort_shim

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__enable__::complete_nosort_shim
@test "terminator::homebrew::__enable__::complete_nosort_shim installs-wrapper-only-on-bash-pre-4.4" {
  # Capture `complete`'s state before invoking the shim so the
  # modern-bash branch can assert it stayed put.
  local before
  before="$(
    declare -f complete 2>/dev/null
    type -t complete 2>/dev/null
  )"

  terminator::homebrew::__enable__::complete_nosort_shim

  if ((BASH_VERSINFO[0] > 4)) \
    || ((BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4)); then
    # Modern bash: shim returns early. `complete` should not be our
    # wrapper, and its state should be unchanged from before.
    local after
    after="$(
      declare -f complete 2>/dev/null
      type -t complete 2>/dev/null
    )"
    [[ "${before}" == "${after}" ]]
    ! declare -f complete 2>/dev/null | grep -q '__strip_nosort_option__'
  else
    # Old bash: shim installs our wrapper as a shell function that
    # delegates to the strip helper.
    [[ "$(type -t complete)" == "function" ]]
    declare -f complete | grep -q '__strip_nosort_option__'
  fi
}

# bats test_tags=terminator::homebrew,terminator::homebrew::__enable__::complete_nosort_shim
@test "terminator::homebrew::__enable__::complete_nosort_shim wrapper-suppresses-nosort-error" {
  # End-to-end: after the shim runs, calling `complete -o nosort ...`
  # must not emit the bash-3.2 "nosort: invalid option name" error.
  # This assertion holds on any bash version: pre-4.4 because the
  # wrapper strips nosort, 4.4+ because the builtin accepts it.
  terminator::homebrew::__enable__::complete_nosort_shim

  local cmd_name='terminator_test_complete_nosort_probe'
  run --separate-stderr complete -o nosort -F _terminator_test_dummy_func "${cmd_name}"
  builtin complete -r "${cmd_name}" 2>/dev/null || true

  assert_success
  # shellcheck disable=SC2154 # `stderr` is set by `run --separate-stderr`
  [[ "${stderr}" != *nosort* ]]
  # shellcheck disable=SC2154 # `stderr` is set by `run --separate-stderr`
  [[ "${stderr}" != *'invalid option'* ]]
}
