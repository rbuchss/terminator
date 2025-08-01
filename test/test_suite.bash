#!/bin/bash

setup_suite() {
  local root_dir

  root_dir="$(repo_root)"

  load "${root_dir}/vendor/test/bats/bats-support/load.bash" # this is required by bats-assert!
  load "${root_dir}/vendor/test/bats/bats-assert/load.bash"

  __export_test_suite_functions__
}

repo_root() {
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
  #
  # To generate these run:
  #
  #   rg --no-line-number --sort=path '\(\) \{' vendor/test/bats/bats-support/src/
  #

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
  #
  # To generate these run:
  #
  #   rg --no-line-number --sort=path '\(\) \{' vendor/test/bats/bats-assert/src/
  #

  # functions in assert.bash
  export -f assert

  # functions in assert_equal.bash
  export -f assert_equal

  # functions in assert_failure.bash
  export -f assert_failure

  # functions in assert_line.bash
  export -f assert_line
  export -f assert_stderr_line
  export -f __assert_line

  # functions in assert_not_equal.bash
  export -f assert_not_equal

  # functions in assert_output.bash
  export -f assert_output
  export -f assert_stderr
  export -f __assert_stream

  # functions in assert_regex.bash
  export -f assert_regex

  # functions in assert_success.bash
  export -f assert_success

  # functions in refute.bash
  export -f refute

  # functions in refute_line.bash
  export -f refute_line
  export -f refute_stderr_line
  export -f __refute_stream_line

  # functions in refute_output.bash
  export -f refute_output
  export -f refute_stderr
  export -f __refute_stream

  # functions in refute_regex.bash
  export -f refute_regex
}
