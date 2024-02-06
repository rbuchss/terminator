#!/bin/bash

setup_suite() {
  local root_dir

  root_dir="$(repo_root)"

  load "${root_dir}/vendor/test/bats/bats-support/load.bash" # this is required by bats-assert!
  load "${root_dir}/vendor/test/bats/bats-assert/load.bash"

  __export_test_suite_functions__
}

function repo_root() {
  git rev-parse --show-toplevel
}

__export_test_suite_functions__() {
  __export_bats_support_functions__
  __export_bats_assert_functions__

  export -f repo_root
}

__export_bats_support_functions__() {
  # Note that we need to export bats-support functions if we want them
  # be just loaded once for the whole suite and to be available when
  # our tests run. The same is true for setup_file.
  # This is since our tests run in sub-shells which will not inherit
  # these function definitions by default.

  # functions from error.bash
  export -f fail

  # functions from lang.bash
  export -f batslib_is_caller

  # functions from output.bash
  export -f batslib_err
  export -f batslib_count_lines
  export -f batslib_is_single_line
  export -f batslib_get_max_single_line_key_width
  export -f batslib_print_kv_single
  export -f batslib_print_kv_multi
  export -f batslib_print_kv_single_or_multi
  export -f batslib_prefix
  export -f batslib_mark
  export -f batslib_decorate
}

__export_bats_assert_functions__() {
  # Note that we need to export bats-assert functions if we want them
  # be just loaded once for the whole suite and to be available when
  # our tests run. The same is true for setup_file.
  # This is since our tests run in sub-shells which will not inherit
  # these function definitions by default.

  # functions in bats-assert are 1:1 with filenames
  export -f assert
  export -f assert_equal
  export -f assert_failure
  export -f assert_line
  export -f assert_not_equal
  export -f assert_output
  export -f assert_regex
  export -f assert_success
  export -f refute
  export -f refute_line
  export -f refute_output
  export -f refute_regex
}
