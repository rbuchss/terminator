#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/__module__.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::__module__::__function_exists__
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::__function_exists__
@test "terminator::__module__::__function_exists__ with-existing-function" {
  run terminator::__module__::__function_exists__ 'terminator::__module__::load'

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::__function_exists__
@test "terminator::__module__::__function_exists__ with-nonexistent-function" {
  run terminator::__module__::__function_exists__ 'nonexistent::function::name'

  assert_failure
}

################################################################################
# terminator::__module__::__invoke_function_if_exists__
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::__invoke_function_if_exists__
@test "terminator::__module__::__invoke_function_if_exists__ with-existing-function" {
  # shellcheck disable=SC2317 # invoked indirectly
  __test_helper_func__() { echo 'invoked'; }

  run terminator::__module__::__invoke_function_if_exists__ '__test_helper_func__'

  assert_success
  assert_output 'invoked'

  unset -f __test_helper_func__
}

# bats test_tags=terminator::__module__,terminator::__module__::__invoke_function_if_exists__
@test "terminator::__module__::__invoke_function_if_exists__ with-nonexistent-function" {
  run terminator::__module__::__invoke_function_if_exists__ 'nonexistent_function_12345'

  assert_success
  assert_output ''
}

# bats test_tags=terminator::__module__,terminator::__module__::__invoke_function_if_exists__
@test "terminator::__module__::__invoke_function_if_exists__ passes-arguments" {
  # shellcheck disable=SC2317 # invoked indirectly
  __test_args_func__() { echo "args: $*"; }

  run terminator::__module__::__invoke_function_if_exists__ '__test_args_func__' 'a' 'b' 'c'

  assert_success
  assert_output 'args: a b c'

  unset -f __test_args_func__
}

################################################################################
# terminator::__module__::__action__
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::__action__
@test "terminator::__module__::__action__ with-invalid-action" {
  run terminator::__module__::__action__ 'test_module' 'invalid_action'

  assert_failure 2
}

# bats test_tags=terminator::__module__,terminator::__module__::__action__
@test "terminator::__module__::__action__ with-valid-load-action" {
  # Reset loaded modules for this test
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=()

  run terminator::__module__::__action__ '__test_module_action__' '__load__'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::__action__
@test "terminator::__module__::__action__ already-in-state" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=('__test_already_loaded__')

  run terminator::__module__::__action__ '__test_already_loaded__' '__load__'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  # Returns 1 when module is already in the desired state
  assert_failure 1
}

################################################################################
# terminator::__module__::__is_in_state__
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ loaded-module" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=('test_module_a' 'test_module_b')

  run terminator::__module__::__is_in_state__ 'test_module_a' '__load__'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ not-loaded-module" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=('test_module_a')

  run terminator::__module__::__is_in_state__ 'test_module_not_loaded' '__load__'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ unload-when-loaded" {
  # For unload action, in_cache means NOT in desired state (inverted logic)
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=('test_module_a')

  run terminator::__module__::__is_in_state__ 'test_module_a' '__unload__'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  # Module is loaded, so it's NOT in "unloaded" state
  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ unload-when-not-loaded" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=()

  run terminator::__module__::__is_in_state__ 'test_module_a' '__unload__'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  # Module is not loaded, so it IS in "unloaded" state
  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ exported-module" {
  local original_exported=("${TERMINATOR_MODULES_EXPORTED[@]}")
  TERMINATOR_MODULES_EXPORTED=('test_module_a')

  run terminator::__module__::__is_in_state__ 'test_module_a' '__export__'

  TERMINATOR_MODULES_EXPORTED=("${original_exported[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ recall-when-exported" {
  local original_exported=("${TERMINATOR_MODULES_EXPORTED[@]}")
  TERMINATOR_MODULES_EXPORTED=('test_module_a')

  run terminator::__module__::__is_in_state__ 'test_module_a' '__recall__'

  TERMINATOR_MODULES_EXPORTED=("${original_exported[@]}")

  # Module is exported, so it's NOT in "recalled" state
  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ enabled-module" {
  local original_enabled=("${TERMINATOR_MODULES_ENABLED[@]}")
  TERMINATOR_MODULES_ENABLED=('test_module_a')

  run terminator::__module__::__is_in_state__ 'test_module_a' '__enable__'

  TERMINATOR_MODULES_ENABLED=("${original_enabled[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ disable-when-enabled" {
  local original_enabled=("${TERMINATOR_MODULES_ENABLED[@]}")
  TERMINATOR_MODULES_ENABLED=('test_module_a')

  run terminator::__module__::__is_in_state__ 'test_module_a' '__disable__'

  TERMINATOR_MODULES_ENABLED=("${original_enabled[@]}")

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::__is_in_state__
@test "terminator::__module__::__is_in_state__ invalid-action" {
  run terminator::__module__::__is_in_state__ 'test_module' 'invalid_action'

  assert_failure 2
}

################################################################################
# terminator::__module__::is_loaded / is_unloaded
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::is_loaded
@test "terminator::__module__::is_loaded with-loaded-module" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=('test_module_check')

  run terminator::__module__::is_loaded 'test_module_check'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::is_loaded
@test "terminator::__module__::is_loaded with-not-loaded-module" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=()

  run terminator::__module__::is_loaded 'test_module_check'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::is_unloaded
@test "terminator::__module__::is_unloaded with-not-loaded-module" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=()

  run terminator::__module__::is_unloaded 'test_module_check'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::is_unloaded
@test "terminator::__module__::is_unloaded with-loaded-module" {
  local original_loaded=("${TERMINATOR_MODULES_LOADED[@]}")
  TERMINATOR_MODULES_LOADED=('test_module_check')

  run terminator::__module__::is_unloaded 'test_module_check'

  TERMINATOR_MODULES_LOADED=("${original_loaded[@]}")

  assert_failure
}

################################################################################
# terminator::__module__::is_exported / is_recalled
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::is_exported
@test "terminator::__module__::is_exported with-exported-module" {
  local original_exported=("${TERMINATOR_MODULES_EXPORTED[@]}")
  TERMINATOR_MODULES_EXPORTED=('test_module_exp')

  run terminator::__module__::is_exported 'test_module_exp'

  TERMINATOR_MODULES_EXPORTED=("${original_exported[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::is_exported
@test "terminator::__module__::is_exported with-not-exported-module" {
  local original_exported=("${TERMINATOR_MODULES_EXPORTED[@]}")
  TERMINATOR_MODULES_EXPORTED=()

  run terminator::__module__::is_exported 'test_module_exp'

  TERMINATOR_MODULES_EXPORTED=("${original_exported[@]}")

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::is_recalled
@test "terminator::__module__::is_recalled with-not-exported-module" {
  local original_exported=("${TERMINATOR_MODULES_EXPORTED[@]}")
  TERMINATOR_MODULES_EXPORTED=()

  run terminator::__module__::is_recalled 'test_module_exp'

  TERMINATOR_MODULES_EXPORTED=("${original_exported[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::is_recalled
@test "terminator::__module__::is_recalled with-exported-module" {
  local original_exported=("${TERMINATOR_MODULES_EXPORTED[@]}")
  TERMINATOR_MODULES_EXPORTED=('test_module_exp')

  run terminator::__module__::is_recalled 'test_module_exp'

  TERMINATOR_MODULES_EXPORTED=("${original_exported[@]}")

  assert_failure
}

################################################################################
# terminator::__module__::is_enabled / is_disabled
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::is_enabled
@test "terminator::__module__::is_enabled with-enabled-module" {
  local original_enabled=("${TERMINATOR_MODULES_ENABLED[@]}")
  TERMINATOR_MODULES_ENABLED=('test_module_en')

  run terminator::__module__::is_enabled 'test_module_en'

  TERMINATOR_MODULES_ENABLED=("${original_enabled[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::is_enabled
@test "terminator::__module__::is_enabled with-not-enabled-module" {
  local original_enabled=("${TERMINATOR_MODULES_ENABLED[@]}")
  TERMINATOR_MODULES_ENABLED=()

  run terminator::__module__::is_enabled 'test_module_en'

  TERMINATOR_MODULES_ENABLED=("${original_enabled[@]}")

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::is_disabled
@test "terminator::__module__::is_disabled with-not-enabled-module" {
  local original_enabled=("${TERMINATOR_MODULES_ENABLED[@]}")
  TERMINATOR_MODULES_ENABLED=()

  run terminator::__module__::is_disabled 'test_module_en'

  TERMINATOR_MODULES_ENABLED=("${original_enabled[@]}")

  assert_success
}

# bats test_tags=terminator::__module__,terminator::__module__::is_disabled
@test "terminator::__module__::is_disabled with-enabled-module" {
  local original_enabled=("${TERMINATOR_MODULES_ENABLED[@]}")
  TERMINATOR_MODULES_ENABLED=('test_module_en')

  run terminator::__module__::is_disabled 'test_module_en'

  TERMINATOR_MODULES_ENABLED=("${original_enabled[@]}")

  assert_failure
}

################################################################################
# terminator::__module__::__get_module_name__
################################################################################

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ with-empty-caller" {
  local result=''

  run terminator::__module__::__get_module_name__ result ''

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ with-NULL-caller" {
  local result=''

  run terminator::__module__::__get_module_name__ result '1 NULL'

  assert_failure
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ derives terminator::vim from vim.sh" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/vim.sh'

  assert_equal "${result}" 'terminator::vim'
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ derives terminator::logger from logger.sh" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/logger.sh'

  assert_equal "${result}" 'terminator::logger'
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ derives terminator::homebrew from homebrew.sh" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/homebrew.sh'

  assert_equal "${result}" 'terminator::homebrew'
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ derives terminator::prompt::git from prompt/git.sh" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/prompt/git.sh'

  assert_equal "${result}" 'terminator::prompt::git'
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ derives terminator::tmux::bootstrap from tmux/bootstrap.sh" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/tmux/bootstrap.sh'

  assert_equal "${result}" 'terminator::tmux::bootstrap'
}

# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ derives terminator::os::darwin from os/darwin.sh" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/os/darwin.sh'

  assert_equal "${result}" 'terminator::os::darwin'
}

# Edge case: .homesick/repos real path
# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ handles .homesick real path" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/Users/russ/.homesick/repos/terminator'

  terminator::__module__::__get_module_name__ result '1 /Users/russ/.homesick/repos/terminator/.terminator/src/vim.sh'

  assert_equal "${result}" 'terminator::vim'
}

# Edge case: homesick symlink path (~/.terminator/src/)
# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ handles symlink path" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/Users/russ'

  terminator::__module__::__get_module_name__ result '1 /Users/russ/.terminator/src/vim.sh'

  assert_equal "${result}" 'terminator::vim'
}

# Edge case: Docker/CI path
# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ handles Docker workspace path" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/workspace'

  terminator::__module__::__get_module_name__ result '1 /workspace/.terminator/src/config.sh'

  assert_equal "${result}" 'terminator::config'
}

# Edge case: preserves underscores in filenames
# bats test_tags=terminator::__module__,terminator::__module__::__get_module_name__
@test "terminator::__module__::__get_module_name__ preserves underscores in filenames" {
  local result=''
  TERMINATOR_MODULE_HOME_DIR='/path/to'

  terminator::__module__::__get_module_name__ result '1 /path/to/.terminator/src/tmux/some_feature.sh'

  assert_equal "${result}" 'terminator::tmux::some_feature'
}
