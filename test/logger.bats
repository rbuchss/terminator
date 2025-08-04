#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/logger.sh'

bats_require_minimum_version 1.5.0

# NOTE that any common envs used in these tests must be standard env vars and not readonly.
# Readonly does not get properly exported to the tests making these vars null.
ISO_8601_TIMESTAMP_PATTERN='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{4})'

LOG_MESSAGES=(
  'Twas brillig, and the slithy toves'
  'Did gyre and gimble in the wabe;'
  'All mimsy were the borogoves,'
  'And the mome raths outgrab'
)

################################################################################
# section: terminator::logger::trace
################################################################################

# bats test_tags=terminator::logger,terminator::logger::trace,output_stderr
@test "terminator::logger::trace" {
  run --separate-stderr \
    terminator::logger::trace \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::trace,output_stderr
@test "terminator::logger::trace level_override=trace" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='trace'

  run --separate-stderr \
    terminator::logger::trace \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^T, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   TRACE -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::trace,output_stderr
@test "terminator::logger::trace level_override=debug" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  run --separate-stderr \
    terminator::logger::trace \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::trace,output_stderr
@test "terminator::logger::trace silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::trace \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: terminator::logger::debug
################################################################################

# bats test_tags=terminator::logger,terminator::logger::debug,output_stderr
@test "terminator::logger::debug" {
  run --separate-stderr \
    terminator::logger::debug \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::debug,output_stderr
@test "terminator::logger::debug level_override=debug" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  run --separate-stderr \
    terminator::logger::debug \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^D, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   DEBUG -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::debug,output_stderr
@test "terminator::logger::debug level_override=info" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='info'

  run --separate-stderr \
    terminator::logger::debug \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::debug,output_stderr
@test "terminator::logger::debug silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::debug \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: terminator::logger::info
################################################################################

# bats test_tags=terminator::logger,terminator::logger::info,output_stderr
@test "terminator::logger::info" {
  local _message

  run --separate-stderr \
    terminator::logger::info \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::info,output_stderr
@test "terminator::logger::info level_override=info" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='info'

  run --separate-stderr \
    terminator::logger::info \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::info,output_stderr
@test "terminator::logger::info level_override=warning" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='warning'

  run --separate-stderr \
    terminator::logger::info \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::info,output_stderr
@test "terminator::logger::info silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::info \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: terminator::logger::warning
################################################################################

# bats test_tags=terminator::logger,terminator::logger::warning,output_stderr
@test "terminator::logger::warning" {
  local _message

  run --separate-stderr \
    terminator::logger::warning \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::warning,output_stderr
@test "terminator::logger::warning level_override=warning" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='warning'

  run --separate-stderr \
    terminator::logger::warning \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::warning,output_stderr
@test "terminator::logger::warning level_override=error" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='error'

  run --separate-stderr \
    terminator::logger::warning \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::warning,output_stderr
@test "terminator::logger::warning silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::warning \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: terminator::logger::error
################################################################################

# bats test_tags=terminator::logger,terminator::logger::error,output_stderr
@test "terminator::logger::error" {
  local _message

  run --separate-stderr \
    terminator::logger::error \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::error,output_stderr
@test "terminator::logger::error level_override=error" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='error'

  run --separate-stderr \
    terminator::logger::error \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::error,output_stderr
@test "terminator::logger::error level_override=fatal" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='fatal'

  run --separate-stderr \
    terminator::logger::error \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::error,output_stderr
@test "terminator::logger::error silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::error \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: terminator::logger::fatal
################################################################################

# bats test_tags=terminator::logger,terminator::logger::fatal,output_stderr
@test "terminator::logger::fatal" {
  local _message

  run --separate-stderr \
    terminator::logger::fatal \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done

  assert_stderr --regexp '-> Traceback \(most recent call last\):'
}

# bats test_tags=terminator::logger,terminator::logger::fatal,output_stderr
@test "terminator::logger::fatal level_override=fatal" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='fatal'

  run --separate-stderr \
    terminator::logger::fatal \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::fatal,output_stderr
@test "terminator::logger::fatal silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::fatal \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: terminator::logger::log
################################################################################

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log" {
  local _message

  run --separate-stderr \
    terminator::logger::log "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level trace" {
  run --separate-stderr \
    terminator::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level trace level_override=trace" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='trace'

  run --separate-stderr \
    terminator::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^T, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   TRACE -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level trace level_override=debug" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  run --separate-stderr \
    terminator::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level trace silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level debug" {
  run --separate-stderr \
    terminator::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level debug level_override=debug" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  run --separate-stderr \
    terminator::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^D, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   DEBUG -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level debug level_override=info" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='info'

  run --separate-stderr \
    terminator::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level debug silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level info" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level info level_override=info" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='info'

  run --separate-stderr \
    terminator::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level info level_override=warning" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='warning'

  run --separate-stderr \
    terminator::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level info silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level warning" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level warning level_override=warning" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='warning'

  run --separate-stderr \
    terminator::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level warning level_override=error" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='error'

  run --separate-stderr \
    terminator::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level warning silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level error" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level error level_override=error" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='error'

  run --separate-stderr \
    terminator::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level error level_override=fatal" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='fatal'

  run --separate-stderr \
    terminator::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level error silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level fatal" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
      --level 'fatal' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done

  assert_stderr --regexp '-> Traceback \(most recent call last\):'
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level fatal level_override=fatal" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='fatal'

  run --separate-stderr \
    terminator::logger::log \
      --level 'fatal' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --level fatal silenced" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run --separate-stderr \
    terminator::logger::log \
      --level 'fatal' \
      "${LOG_MESSAGES[@]}"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stdout
@test "terminator::logger::log --output /dev/stdout" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
    --output /dev/stdout \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_stderr
  assert_output --regexp '^I, '
  assert_output --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_output --regexp '#[0-9]+'
  assert_output --regexp '    INFO -- '
  assert_output --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_output --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_null
@test "terminator::logger::log --output /dev/null" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
    --output /dev/null \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_stderr
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::log,output_file
@test "terminator::logger::log --output tempfile" {
  local \
    _message \
    _file \
    _file_content

  _file="$(mktemp "${BATS_TEST_TMPDIR}/out.XXXXXX")"

  run --separate-stderr \
    terminator::logger::log \
    --output "${_file}" \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_stderr
  refute_output

  _file_content="$(cat "${_file}")"

  assert_regex "${_file_content}" '^I, '
  assert_regex "${_file_content}" "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_regex "${_file_content}" '#[0-9]+'
  assert_regex "${_file_content}" '    INFO -- '
  assert_regex "${_file_content}" ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_regex "${_file_content}" "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --caller-level 1" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
    --caller-level 1 \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' run: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --caller-level 4" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
    --caller-level 4 \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' main: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --help" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
    --help \
    "${LOG_MESSAGES[@]}"

  assert_failure "${TERMINATOR_LOG_INVALID_STATUS}"
  refute_output
  assert_stderr --regexp '^Usage: terminator::logger::log'
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log --invalid" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
    --invalid \
    "${LOG_MESSAGES[@]}"

  assert_failure "${TERMINATOR_LOG_INVALID_STATUS}"
  refute_output
  assert_stderr --regexp "^ERROR: terminator::logger::log invalid option: '--invalid'"
  assert_stderr --regexp 'Usage: terminator::logger::log'
}

# bats test_tags=terminator::logger,terminator::logger::log,output_stderr
@test "terminator::logger::log -- --not-included-flag" {
  local _message

  run --separate-stderr \
    terminator::logger::log \
      -- \
      --not-included-flag \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  assert_stderr --regexp '--not-included-flag'

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

################################################################################
# section: terminator::logger::datetime
################################################################################

# bats test_tags=terminator::logger,terminator::logger::datetime,output_stdout
@test "terminator::logger::datetime" {
  run terminator::logger::datetime

  assert_success
  assert_output --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
}

# bats test_tags=terminator::logger,terminator::logger::datetime,output_stdout
@test "terminator::logger::datetime fallback to /bin/date" {
  local original_path="${PATH}"

  PATH='/nonexistent/bin'

  run terminator::logger::datetime

  PATH="${original_path}"

  assert_success
  assert_output --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
}

################################################################################
# section: terminator::logger::severity
################################################################################

# bats test_tags=terminator::logger,terminator::logger::severity,output_stdout
@test "terminator::logger::severity" {
  run terminator::logger::severity

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_INFO}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_var
@test "terminator::logger::severity result" {
  local \
    result \
    _status=0

  terminator::logger::severity result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_INFO}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_var
@test "terminator::logger::severity result -> no output" {
  local result

  run terminator::logger::severity result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_stdout
@test "terminator::logger::severity level_override" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  run terminator::logger::severity

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_var
@test "terminator::logger::severity result level_override" {
  local \
    result \
    _status=0 \
    original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  terminator::logger::severity result \
    || _status="$?"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_stdout
@test "terminator::logger::severity level_variable_override" {
  __override__TERMINATOR_LOG_LEVEL='trace'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'

  run terminator::logger::severity

  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_TRACE}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_var
@test "terminator::logger::severity result level_variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_LEVEL='trace'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'

  terminator::logger::severity result \
    || _status="$?"

  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_TRACE}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_stdout
@test "terminator::logger::severity default_override" {
  local \
    original_log_level="${TERMINATOR_LOG_LEVEL}" \
    original_log_level_default="${TERMINATOR_LOG_LEVEL_DEFAULT}"

  unset TERMINATOR_LOG_LEVEL
  TERMINATOR_LOG_LEVEL_DEFAULT='error'

  run terminator::logger::severity

  TERMINATOR_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_ERROR}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_var
@test "terminator::logger::severity result default_override" {
  local \
    result \
    _status=0 \
    original_log_level="${TERMINATOR_LOG_LEVEL}" \
    original_log_level_default="${TERMINATOR_LOG_LEVEL_DEFAULT}"

  unset TERMINATOR_LOG_LEVEL
  TERMINATOR_LOG_LEVEL_DEFAULT='error'

  terminator::logger::severity result \
    || _status="$?"

  TERMINATOR_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_ERROR}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_stdout
@test "terminator::logger::severity default_variable_override" {
  unset __override__TERMINATOR_LOG_LEVEL
  __override__TERMINATOR_LOG_LEVEL_DEFAULT='warning'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  run terminator::logger::severity

  terminator::logger::level_default::unset_variable
  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_WARNING}"
}

# bats test_tags=terminator::logger,terminator::logger::severity,output_var
@test "terminator::logger::severity result default_variable_override" {
  local result _status=0

  unset __override__TERMINATOR_LOG_LEVEL
  __override__TERMINATOR_LOG_LEVEL_DEFAULT='warning'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  terminator::logger::severity result \
    || _status="$?"

  terminator::logger::level_default::unset_variable
  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_WARNING}"
}

################################################################################
# section: terminator::logger::severity_from_level
################################################################################

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level trace" {
  run terminator::logger::severity_from_level trace

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_TRACE}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level TRACE" {
  run terminator::logger::severity_from_level TRACE

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_TRACE}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Trace" {
  run terminator::logger::severity_from_level Trace

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_TRACE}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level trace result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level trace result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_TRACE}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level trace result -> no output" {
  local result

  run terminator::logger::severity_from_level trace result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level debug" {
  run terminator::logger::severity_from_level debug

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level DEBUG" {
  run terminator::logger::severity_from_level DEBUG

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Debug" {
  run terminator::logger::severity_from_level Debug

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level debug result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level debug result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level debug result -> no output" {
  local result

  run terminator::logger::severity_from_level debug result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level info" {
  run terminator::logger::severity_from_level info

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_INFO}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level INFO" {
  run terminator::logger::severity_from_level INFO

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_INFO}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Info" {
  run terminator::logger::severity_from_level Info

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_INFO}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level info result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level info result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_INFO}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level info result -> no output" {
  local result

  run terminator::logger::severity_from_level info result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level warning" {
  run terminator::logger::severity_from_level warning

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_WARNING}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level WARNING" {
  run terminator::logger::severity_from_level WARNING

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_WARNING}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Warning" {
  run terminator::logger::severity_from_level Warning

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_WARNING}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level warning result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level warning result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_WARNING}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level warning result -> no output" {
  local result

  run terminator::logger::severity_from_level warning result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level error" {
  run terminator::logger::severity_from_level error

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_ERROR}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level ERROR" {
  run terminator::logger::severity_from_level ERROR

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_ERROR}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Error" {
  run terminator::logger::severity_from_level Error

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_ERROR}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level error result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level error result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_ERROR}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level error result -> no output" {
  local result

  run terminator::logger::severity_from_level error result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level fatal" {
  run terminator::logger::severity_from_level fatal

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level FATAL" {
  run terminator::logger::severity_from_level FATAL

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Fatal" {
  run terminator::logger::severity_from_level Fatal

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level fatal result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level fatal result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level fatal result -> no output" {
  local result

  run terminator::logger::severity_from_level fatal result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level invalid" {
  run terminator::logger::severity_from_level invalid

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level INVALID" {
  run terminator::logger::severity_from_level INVALID

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_stdout
@test "terminator::logger::severity_from_level Invalid" {
  run terminator::logger::severity_from_level Invalid

  assert_success
  assert_output "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level invalid result" {
  local \
    result \
    _status=0

  terminator::logger::severity_from_level invalid result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${TERMINATOR_LOG_SEVERITY_FATAL}"
}

# bats test_tags=terminator::logger,terminator::logger::severity_from_level,output_var
@test "terminator::logger::severity_from_level invalid result -> no output" {
  local result

  run terminator::logger::severity_from_level invalid result

  assert_success
  refute_output
}

################################################################################
# section: terminator::logger::level
################################################################################

# bats test_tags=terminator::logger,terminator::logger::level,output_stdout
@test "terminator::logger::level" {
  run terminator::logger::level

  assert_success
  assert_output 'info'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_var
@test "terminator::logger::level result" {
  local \
    result \
    _status=0

  terminator::logger::level result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'info'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_var
@test "terminator::logger::level result -> no output" {
  local result

  run terminator::logger::level result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::level,output_stdout
@test "terminator::logger::level level_override" {
  local original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  run terminator::logger::level

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output 'debug'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_var
@test "terminator::logger::level result level_override" {
  local \
    result \
    _status=0 \
    original_log_level="${TERMINATOR_LOG_LEVEL}"

  TERMINATOR_LOG_LEVEL='debug'

  terminator::logger::level result \
    || _status="$?"

  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'debug'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_stdout
@test "terminator::logger::level level_variable_override" {
  __override__TERMINATOR_LOG_LEVEL='trace'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'

  run terminator::logger::level

  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL

  assert_success
  assert_output 'trace'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_var
@test "terminator::logger::level result level_variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_LEVEL='trace'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'

  terminator::logger::level result \
    || _status="$?"

  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL

  assert_equal "${_status}" 0
  assert_equal "${result}" 'trace'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_stdout
@test "terminator::logger::level default_override" {
  local \
    original_log_level="${TERMINATOR_LOG_LEVEL}" \
    original_log_level_default="${TERMINATOR_LOG_LEVEL_DEFAULT}"

  unset TERMINATOR_LOG_LEVEL
  TERMINATOR_LOG_LEVEL_DEFAULT='error'

  run terminator::logger::level

  TERMINATOR_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output 'error'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_var
@test "terminator::logger::level result default_override" {
  local \
    result \
    _status=0 \
    original_log_level="${TERMINATOR_LOG_LEVEL}" \
    original_log_level_default="${TERMINATOR_LOG_LEVEL_DEFAULT}"

  unset TERMINATOR_LOG_LEVEL
  TERMINATOR_LOG_LEVEL_DEFAULT='error'

  terminator::logger::level result \
    || _status="$?"

  TERMINATOR_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  TERMINATOR_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'error'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_stdout
@test "terminator::logger::level default_variable_override" {
  unset __override__TERMINATOR_LOG_LEVEL
  __override__TERMINATOR_LOG_LEVEL_DEFAULT='warning'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  run terminator::logger::level

  terminator::logger::level_default::unset_variable
  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_success
  assert_output 'warning'
}

# bats test_tags=terminator::logger,terminator::logger::level,output_var
@test "terminator::logger::level result default_variable_override" {
  local result _status=0

  unset __override__TERMINATOR_LOG_LEVEL
  __override__TERMINATOR_LOG_LEVEL_DEFAULT='warning'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  terminator::logger::level result \
    || _status="$?"

  terminator::logger::level_default::unset_variable
  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" 'warning'
}

################################################################################
# section: terminator::logger::level::variable
################################################################################

# bats test_tags=terminator::logger,terminator::logger::level::variable,output_stdout
@test "terminator::logger::level::variable" {
  run terminator::logger::level::variable

  assert_success
  assert_output 'TERMINATOR_LOG_LEVEL'
}

# bats test_tags=terminator::logger,terminator::logger::level::variable,output_var
@test "terminator::logger::level::variable result" {
  local \
    result \
    _status=0

  terminator::logger::level::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'TERMINATOR_LOG_LEVEL'
}

# bats test_tags=terminator::logger,terminator::logger::level::variable,output_var
@test "terminator::logger::level::variable result -> no output" {
  local result

  run terminator::logger::level::variable result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::level::variable,output_stdout
@test "terminator::logger::level::variable variable_override" {
  __override__TERMINATOR_LOG_LEVEL='debug'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'

  run terminator::logger::level::variable

  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL

  assert_success
  assert_output '__override__TERMINATOR_LOG_LEVEL'
}

# bats test_tags=terminator::logger,terminator::logger::level::variable,output_var
@test "terminator::logger::level::variable result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_LEVEL='debug'
  terminator::logger::level::set_variable '__override__TERMINATOR_LOG_LEVEL'

  terminator::logger::level::variable result \
    || _status="$?"

  terminator::logger::level::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__TERMINATOR_LOG_LEVEL'
}

################################################################################
# section: terminator::logger::level_default
################################################################################

# bats test_tags=terminator::logger,terminator::logger::level_default,output_stdout
@test "terminator::logger::level_default" {
  run terminator::logger::level_default

  assert_success
  assert_output 'info'
}

# bats test_tags=terminator::logger,terminator::logger::level_default,output_var
@test "terminator::logger::level_default result" {
  local \
    result \
    _status=0

  terminator::logger::level_default result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'info'
}

# bats test_tags=terminator::logger,terminator::logger::level_default,output_var
@test "terminator::logger::level_default result -> no output" {
  local result

  run terminator::logger::level_default result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::level_default,output_stdout
@test "terminator::logger::level_default override" {
  local original_log_level_default="${TERMINATOR_LOG_LEVEL_DEFAULT}"

  TERMINATOR_LOG_LEVEL_DEFAULT='error'

  run terminator::logger::level_default

  TERMINATOR_LOG_LEVEL_DEFAULT="${original_log_level_default}"

  assert_success
  assert_output 'error'
}

# bats test_tags=terminator::logger,terminator::logger::level_default,output_var
@test "terminator::logger::level_default result override" {
  local \
    result \
    _status=0 \
    original_log_level_default="${TERMINATOR_LOG_LEVEL_DEFAULT}"

  TERMINATOR_LOG_LEVEL_DEFAULT='error'

  terminator::logger::level_default result \
    || _status="$?"

  TERMINATOR_LOG_LEVEL_DEFAULT="${original_log_level_default}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'error'
}

# bats test_tags=terminator::logger,terminator::logger::level_default,output_stdout
@test "terminator::logger::level_default variable_override" {
  __override__TERMINATOR_LOG_LEVEL_DEFAULT='warning'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  run terminator::logger::level_default

  terminator::logger::level_default::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_success
  assert_output 'warning'
}

# bats test_tags=terminator::logger,terminator::logger::level_default,output_var
@test "terminator::logger::level_default result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_LEVEL_DEFAULT='warning'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  terminator::logger::level_default result \
    || _status="$?"

  terminator::logger::level_default::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" 'warning'
}

################################################################################
# section: terminator::logger::level_default::variable
################################################################################

# bats test_tags=terminator::logger,terminator::logger::level_default::variable,output_stdout
@test "terminator::logger::level_default::variable" {
  run terminator::logger::level_default::variable

  assert_success
  assert_output 'TERMINATOR_LOG_LEVEL_DEFAULT'
}

# bats test_tags=terminator::logger,terminator::logger::level_default::variable,output_var
@test "terminator::logger::level_default::variable result" {
  local \
    result \
    _status=0

  terminator::logger::level_default::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'TERMINATOR_LOG_LEVEL_DEFAULT'
}

# bats test_tags=terminator::logger,terminator::logger::level_default::variable,output_var
@test "terminator::logger::level_default::variable result -> no output" {
  local result

  run terminator::logger::level_default::variable result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::level_default::variable,output_stdout
@test "terminator::logger::level_default::variable variable_override" {
  __override__TERMINATOR_LOG_LEVEL_DEFAULT='debug'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  run terminator::logger::level_default::variable

  terminator::logger::level_default::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_success
  assert_output '__override__TERMINATOR_LOG_LEVEL_DEFAULT'
}

# bats test_tags=terminator::logger,terminator::logger::level_default::variable,output_var
@test "terminator::logger::level_default::variable result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_LEVEL_DEFAULT='debug'
  terminator::logger::level_default::set_variable '__override__TERMINATOR_LOG_LEVEL_DEFAULT'

  terminator::logger::level_default::variable result \
    || _status="$?"

  terminator::logger::level_default::unset_variable
  unset __override__TERMINATOR_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__TERMINATOR_LOG_LEVEL_DEFAULT'
}

################################################################################
# section: terminator::logger::output_default
################################################################################

# bats test_tags=terminator::logger,terminator::logger::output_default,output_stdout
@test "terminator::logger::output_default" {
  run terminator::logger::output_default

  assert_success
  assert_output '/dev/stderr'
}

# bats test_tags=terminator::logger,terminator::logger::output_default,output_var
@test "terminator::logger::output_default result" {
  local \
    result \
    _status=0

  terminator::logger::output_default result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '/dev/stderr'
}

# bats test_tags=terminator::logger,terminator::logger::output_default,output_var
@test "terminator::logger::output_default result -> no output" {
  local result

  run terminator::logger::output_default result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::output_default,output_stdout
@test "terminator::logger::output_default override" {
  local original_log_output_default="${TERMINATOR_LOG_OUTPUT_DEFAULT}"

  TERMINATOR_LOG_OUTPUT_DEFAULT='/dev/stdout'

  run terminator::logger::output_default

  TERMINATOR_LOG_OUTPUT_DEFAULT="${original_log_output_default}"

  assert_success
  assert_output '/dev/stdout'
}

# bats test_tags=terminator::logger,terminator::logger::output_default,output_var
@test "terminator::logger::output_default result override" {
  local \
    result \
    _status=0 \
    original_log_output_default="${TERMINATOR_LOG_OUTPUT_DEFAULT}"

  TERMINATOR_LOG_OUTPUT_DEFAULT='/dev/stdout'

  terminator::logger::output_default result \
    || _status="$?"

  TERMINATOR_LOG_OUTPUT_DEFAULT="${original_log_output_default}"

  assert_equal "${_status}" 0
  assert_equal "${result}" '/dev/stdout'
}

# bats test_tags=terminator::logger,terminator::logger::output_default,output_stdout
@test "terminator::logger::output_default variable_override" {
  __override__TERMINATOR_LOG_OUTPUT_DEFAULT='my.log'
  terminator::logger::output_default::set_variable '__override__TERMINATOR_LOG_OUTPUT_DEFAULT'

  run terminator::logger::output_default

  terminator::logger::output_default::unset_variable
  unset __override__TERMINATOR_LOG_OUTPUT_DEFAULT

  assert_success
  assert_output 'my.log'
}

# bats test_tags=terminator::logger,terminator::logger::output_default,output_var
@test "terminator::logger::output_default result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_OUTPUT_DEFAULT='my.log'
  terminator::logger::output_default::set_variable '__override__TERMINATOR_LOG_OUTPUT_DEFAULT'

  terminator::logger::output_default result \
    || _status="$?"

  terminator::logger::output_default::unset_variable
  unset __override__TERMINATOR_LOG_OUTPUT_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" 'my.log'
}

################################################################################
# section: terminator::logger::output_default::variable
################################################################################

# bats test_tags=terminator::logger,terminator::logger::output_default::variable,output_stdout
@test "terminator::logger::output_default::variable" {
  run terminator::logger::output_default::variable

  assert_success
  assert_output 'TERMINATOR_LOG_OUTPUT_DEFAULT'
}

# bats test_tags=terminator::logger,terminator::logger::output_default::variable,output_var
@test "terminator::logger::output_default::variable result" {
  local \
    result \
    _status=0

  terminator::logger::output_default::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'TERMINATOR_LOG_OUTPUT_DEFAULT'
}

# bats test_tags=terminator::logger,terminator::logger::output_default::variable,output_var
@test "terminator::logger::output_default::variable result -> no output" {
  local result

  run terminator::logger::output_default::variable result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::output_default::variable,output_stdout
@test "terminator::logger::output_default::variable variable_override" {
  __override__TERMINATOR_LOG_OUTPUT_DEFAULT='debug'
  terminator::logger::output_default::set_variable '__override__TERMINATOR_LOG_OUTPUT_DEFAULT'

  run terminator::logger::output_default::variable

  terminator::logger::output_default::unset_variable
  unset __override__TERMINATOR_LOG_OUTPUT_DEFAULT

  assert_success
  assert_output '__override__TERMINATOR_LOG_OUTPUT_DEFAULT'
}

# bats test_tags=terminator::logger,terminator::logger::output_default::variable,output_var
@test "terminator::logger::output_default::variable result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_OUTPUT_DEFAULT='debug'
  terminator::logger::output_default::set_variable '__override__TERMINATOR_LOG_OUTPUT_DEFAULT'

  terminator::logger::output_default::variable result \
    || _status="$?"

  terminator::logger::output_default::unset_variable
  unset __override__TERMINATOR_LOG_OUTPUT_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__TERMINATOR_LOG_OUTPUT_DEFAULT'
}

################################################################################
# section: terminator::logger::is_silenced
################################################################################

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced" {
  run terminator::logger::is_silenced

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = 1" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override > 1" {
  __override__TERMINATOR_LOG_SILENCE=42
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_success
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = true" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=true

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override = TRUE" {
  __override__TERMINATOR_LOG_SILENCE=TRUE
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_success
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = yes" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=yes

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override = YES" {
  __override__TERMINATOR_LOG_SILENCE=YES
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_success
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = 0" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=0

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override < 0" {
  __override__TERMINATOR_LOG_SILENCE=-42
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = false" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=false

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override = FALSE" {
  __override__TERMINATOR_LOG_SILENCE=FALSE
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = no" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=no

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override = NO" {
  __override__TERMINATOR_LOG_SILENCE=NO
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced override = invalid" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=invalid

  run terminator::logger::is_silenced

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=terminator::logger,terminator::logger::is_silenced
@test "terminator::logger::is_silenced variable_override unset" {
  unset __override__TERMINATOR_LOG_SILENCE
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::is_silenced

  terminator::logger::silence::unset_variable

  assert_failure
}

################################################################################
# section: terminator::logger::silence
################################################################################

# bats test_tags=terminator::logger,terminator::logger::silence,output_stdout
@test "terminator::logger::silence" {
  run terminator::logger::silence

  assert_success
  assert_output 0
}

# bats test_tags=terminator::logger,terminator::logger::silence,output_var
@test "terminator::logger::silence result" {
  local \
    result \
    _status=0

  terminator::logger::silence result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 0
}

# bats test_tags=terminator::logger,terminator::logger::silence,output_var
@test "terminator::logger::silence result -> no output" {
  local result

  run terminator::logger::silence result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::silence,output_stdout
@test "terminator::logger::silence override" {
  local original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  run terminator::logger::silence

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_success
  assert_output 1
}

# bats test_tags=terminator::logger,terminator::logger::silence,output_var
@test "terminator::logger::silence result override" {
  local \
    result \
    _status=0 \
    original_log_silence="${TERMINATOR_LOG_SILENCE}"

  TERMINATOR_LOG_SILENCE=1

  terminator::logger::silence result \
    || _status="$?"

  TERMINATOR_LOG_SILENCE="${original_log_silence}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 1
}

# bats test_tags=terminator::logger,terminator::logger::silence,output_stdout
@test "terminator::logger::silence variable_override" {
  __override__TERMINATOR_LOG_SILENCE=42
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::silence

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_success
  assert_output 42
}

# bats test_tags=terminator::logger,terminator::logger::silence,output_var
@test "terminator::logger::silence result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_SILENCE=42
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  terminator::logger::silence result \
    || _status="$?"

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_equal "${_status}" 0
  assert_equal "${result}" 42
}

################################################################################
# section: terminator::logger::silence::variable
################################################################################

# bats test_tags=terminator::logger,terminator::logger::silence::variable,output_stdout
@test "terminator::logger::silence::variable" {
  run terminator::logger::silence::variable

  assert_success
  assert_output 'TERMINATOR_LOG_SILENCE'
}

# bats test_tags=terminator::logger,terminator::logger::silence::variable,output_var
@test "terminator::logger::silence::variable result" {
  local \
    result \
    _status=0

  terminator::logger::silence::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'TERMINATOR_LOG_SILENCE'
}

# bats test_tags=terminator::logger,terminator::logger::silence::variable,output_var
@test "terminator::logger::silence::variable result -> no output" {
  local result

  run terminator::logger::silence::variable result

  assert_success
  refute_output
}

# bats test_tags=terminator::logger,terminator::logger::silence::variable,output_stdout
@test "terminator::logger::silence::variable variable_override" {
  __override__TERMINATOR_LOG_SILENCE=1
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  run terminator::logger::silence::variable

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_success
  assert_output '__override__TERMINATOR_LOG_SILENCE'
}

# bats test_tags=terminator::logger,terminator::logger::silence::variable,output_var
@test "terminator::logger::silence::variable result variable_override" {
  local \
    result \
    _status=0

  __override__TERMINATOR_LOG_SILENCE=1
  terminator::logger::silence::set_variable '__override__TERMINATOR_LOG_SILENCE'

  terminator::logger::silence::variable result \
    || _status="$?"

  terminator::logger::silence::unset_variable
  unset __override__TERMINATOR_LOG_SILENCE

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__TERMINATOR_LOG_SILENCE'
}
