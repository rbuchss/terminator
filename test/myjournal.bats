#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/myjournal.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::myjournal::root_dir
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::root_dir
@test "terminator::myjournal::root_dir default" {
  local original="${TERMINATOR_MYJOURNAL_DIR}"
  unset TERMINATOR_MYJOURNAL_DIR

  run terminator::myjournal::root_dir

  TERMINATOR_MYJOURNAL_DIR="${original}"

  assert_success
  assert_output "${HOME}/vaults/chronicle/Journal"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::root_dir
@test "terminator::myjournal::root_dir with-override" {
  local original="${TERMINATOR_MYJOURNAL_DIR}"
  TERMINATOR_MYJOURNAL_DIR='/custom/journal/path'

  run terminator::myjournal::root_dir

  TERMINATOR_MYJOURNAL_DIR="${original}"

  assert_success
  assert_output '/custom/journal/path'
}

################################################################################
# terminator::myjournal::valid_name
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-valid-date" {
  run terminator::myjournal::valid_name '2025/12/11'

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-today" {
  run terminator::myjournal::valid_name 'today'

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-tomorrow" {
  run terminator::myjournal::valid_name 'tomorrow'

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-yesterday" {
  run terminator::myjournal::valid_name 'yesterday'

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-invalid-format" {
  run terminator::myjournal::valid_name 'not-a-date'

  assert_failure
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-partial-date" {
  run terminator::myjournal::valid_name '2025/12'

  assert_failure
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-empty" {
  run terminator::myjournal::valid_name ''

  assert_failure
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-dashes-instead-of-slashes" {
  run terminator::myjournal::valid_name '2025-12-11'

  assert_failure
}

# bats test_tags=terminator::myjournal,terminator::myjournal::valid_name
@test "terminator::myjournal::valid_name with-extra-path" {
  run terminator::myjournal::valid_name '2025/12/11/extra'

  assert_failure
}

################################################################################
# terminator::myjournal::convert_keyword_to_date
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::convert_keyword_to_date
@test "terminator::myjournal::convert_keyword_to_date today" {
  local expected
  expected="$(date +'%Y/%m/%d')"

  run terminator::myjournal::convert_keyword_to_date 'today'

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::convert_keyword_to_date
@test "terminator::myjournal::convert_keyword_to_date tomorrow" {
  # BusyBox date does not support GNU -d or BSD -v date arithmetic
  if ! date -d '+1 day' +'%Y/%m/%d' 2>/dev/null \
    && ! date -v+1d +'%Y/%m/%d' 2>/dev/null; then
    skip 'date arithmetic not supported (BusyBox)'
  fi

  run terminator::myjournal::convert_keyword_to_date 'tomorrow'

  assert_success
  # Output should be a valid date in YYYY/MM/DD format
  assert_output --regexp '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::convert_keyword_to_date
@test "terminator::myjournal::convert_keyword_to_date yesterday" {
  # BusyBox date does not support GNU -d or BSD -v date arithmetic
  if ! date -d '-1 day' +'%Y/%m/%d' 2>/dev/null \
    && ! date -v-1d +'%Y/%m/%d' 2>/dev/null; then
    skip 'date arithmetic not supported (BusyBox)'
  fi

  run terminator::myjournal::convert_keyword_to_date 'yesterday'

  assert_success
  assert_output --regexp '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::convert_keyword_to_date
@test "terminator::myjournal::convert_keyword_to_date passthrough" {
  run terminator::myjournal::convert_keyword_to_date '2025/06/15'

  assert_success
  assert_output '2025/06/15'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::convert_keyword_to_date
@test "terminator::myjournal::convert_keyword_to_date arbitrary-string-passthrough" {
  run terminator::myjournal::convert_keyword_to_date 'some-random-string'

  assert_success
  assert_output 'some-random-string'
}

################################################################################
# terminator::myjournal::template
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-valid-date" {
  run terminator::myjournal::template '2025/12/11'

  assert_success
  assert_output --partial '---'
  assert_output --partial 'id: 2025-12-11'
  assert_output --partial 'tags:'
  assert_output --partial '  - daily-notes'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-invalid-name" {
  run --separate-stderr terminator::myjournal::template 'invalid'

  assert_failure 1
}

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-extra-tags" {
  local original="${OBSIDIAN_DAILY_NOTE_EXTRA_TAGS}"
  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS='work,personal'

  run terminator::myjournal::template '2025/12/11'

  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS="${original}"

  assert_success
  assert_output --partial '  - daily-notes'
  assert_output --partial '  - work'
  assert_output --partial '  - personal'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-duplicate-tag" {
  local original="${OBSIDIAN_DAILY_NOTE_EXTRA_TAGS}"
  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS='daily-notes,extra'

  run terminator::myjournal::template '2025/12/11'

  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS="${original}"

  assert_success
  assert_output --partial '  - daily-notes'
  assert_output --partial '  - extra'
  # daily-notes should appear only once
  local count
  count="$(echo "${output}" | grep -c '  - daily-notes')"
  assert_equal "${count}" '1'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-empty-extra-tags" {
  local original="${OBSIDIAN_DAILY_NOTE_EXTRA_TAGS}"
  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS=''

  run terminator::myjournal::template '2025/12/11'

  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS="${original}"

  assert_success
  assert_output --partial '  - daily-notes'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-whitespace-extra-tags" {
  local original="${OBSIDIAN_DAILY_NOTE_EXTRA_TAGS}"
  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS='  work  ,  personal  '

  run terminator::myjournal::template '2025/12/11'

  OBSIDIAN_DAILY_NOTE_EXTRA_TAGS="${original}"

  assert_success
  assert_output --partial '  - work'
  assert_output --partial '  - personal'
}

################################################################################
# terminator::myjournal::new_entry
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::new_entry
@test "terminator::myjournal::new_entry with-empty-filepath" {
  run --separate-stderr terminator::myjournal::new_entry ''

  assert_failure 1
}

# bats test_tags=terminator::myjournal,terminator::myjournal::new_entry
@test "terminator::myjournal::new_entry with-no-args" {
  run --separate-stderr terminator::myjournal::new_entry

  assert_failure 1
}

# bats test_tags=terminator::myjournal,terminator::myjournal::new_entry
@test "terminator::myjournal::new_entry creates-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  TERMINATOR_MYJOURNAL_DIR="${temp_dir}"

  local journal_filepath="${temp_dir}/2025/12/11.md"

  terminator::myjournal::new_entry "${journal_filepath}"
  local result=$?

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"

  assert_equal "${result}" '0'
  [[ -f "${journal_filepath}" ]]
  # Verify content has frontmatter
  local content
  content="$(cat "${journal_filepath}")"
  [[ "${content}" == *'id: 2025-12-11'* ]]
  [[ "${content}" == *'daily-notes'* ]]

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::new_entry
@test "terminator::myjournal::new_entry creates-parent-directories" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  TERMINATOR_MYJOURNAL_DIR="${temp_dir}"

  local journal_filepath="${temp_dir}/2025/12/11.md"

  # Ensure the parent directory does not exist
  [[ ! -d "${temp_dir}/2025/12" ]]

  terminator::myjournal::new_entry "${journal_filepath}"

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"

  [[ -d "${temp_dir}/2025/12" ]]
  [[ -f "${journal_filepath}" ]]

  rm -rf "${temp_dir}"
}
