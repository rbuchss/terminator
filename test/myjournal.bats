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
  run terminator::myjournal::convert_keyword_to_date 'tomorrow'

  assert_success
  # Output should be a valid date in YYYY/MM/DD format
  assert_output --regexp '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::convert_keyword_to_date
@test "terminator::myjournal::convert_keyword_to_date yesterday" {
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
@test "terminator::myjournal::template with-registered-tags" {
  local -a original=("${TERMINATOR_MYJOURNAL_TAGS[@]}")
  TERMINATOR_MYJOURNAL_TAGS=('daily-notes' 'work' 'personal')

  run terminator::myjournal::template '2025/12/11'

  TERMINATOR_MYJOURNAL_TAGS=("${original[@]}")

  assert_success
  assert_output --partial '  - daily-notes'
  assert_output --partial '  - work'
  assert_output --partial '  - personal'
}

# bats test_tags=terminator::myjournal,terminator::myjournal::template
@test "terminator::myjournal::template with-default-tags-only" {
  local -a original=("${TERMINATOR_MYJOURNAL_TAGS[@]}")
  TERMINATOR_MYJOURNAL_TAGS=('daily-notes')

  run terminator::myjournal::template '2025/12/11'

  TERMINATOR_MYJOURNAL_TAGS=("${original[@]}")

  assert_success
  assert_output --partial '  - daily-notes'
}

################################################################################
# terminator::myjournal::tag
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::tag
@test "terminator::myjournal::tag when-missing-name-flag" {
  run terminator::myjournal::tag

  assert_failure 1
}

# bats test_tags=terminator::myjournal,terminator::myjournal::tag
@test "terminator::myjournal::tag adds-single-tag" {
  local -a original=("${TERMINATOR_MYJOURNAL_TAGS[@]}")
  TERMINATOR_MYJOURNAL_TAGS=('daily-notes')

  terminator::myjournal::tag --name work

  ((${#TERMINATOR_MYJOURNAL_TAGS[@]} == 2))
  [[ "${TERMINATOR_MYJOURNAL_TAGS[1]}" == "work" ]]

  TERMINATOR_MYJOURNAL_TAGS=("${original[@]}")
}

# bats test_tags=terminator::myjournal,terminator::myjournal::tag
@test "terminator::myjournal::tag adds-multiple-tags" {
  local -a original=("${TERMINATOR_MYJOURNAL_TAGS[@]}")
  TERMINATOR_MYJOURNAL_TAGS=('daily-notes')

  terminator::myjournal::tag --name work --name personal

  ((${#TERMINATOR_MYJOURNAL_TAGS[@]} == 3))
  [[ "${TERMINATOR_MYJOURNAL_TAGS[1]}" == "work" ]]
  [[ "${TERMINATOR_MYJOURNAL_TAGS[2]}" == "personal" ]]

  TERMINATOR_MYJOURNAL_TAGS=("${original[@]}")
}

# bats test_tags=terminator::myjournal,terminator::myjournal::tag
@test "terminator::myjournal::tag skips-duplicates" {
  local -a original=("${TERMINATOR_MYJOURNAL_TAGS[@]}")
  TERMINATOR_MYJOURNAL_TAGS=('daily-notes')

  terminator::myjournal::tag --name daily-notes --name extra

  ((${#TERMINATOR_MYJOURNAL_TAGS[@]} == 2))
  [[ "${TERMINATOR_MYJOURNAL_TAGS[0]}" == "daily-notes" ]]
  [[ "${TERMINATOR_MYJOURNAL_TAGS[1]}" == "extra" ]]

  TERMINATOR_MYJOURNAL_TAGS=("${original[@]}")
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

################################################################################
# terminator::myjournal::autocreate_enabled
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::autocreate_enabled
@test "terminator::myjournal::autocreate_enabled default-off" {
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  unset TERMINATOR_MYJOURNAL_AUTOCREATE

  run terminator::myjournal::autocreate_enabled

  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_failure
}

# bats test_tags=terminator::myjournal,terminator::myjournal::autocreate_enabled
@test "terminator::myjournal::autocreate_enabled enabled-with-1" {
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='1'

  run terminator::myjournal::autocreate_enabled

  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::autocreate_enabled
@test "terminator::myjournal::autocreate_enabled enabled-with-true" {
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='true'

  run terminator::myjournal::autocreate_enabled

  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::autocreate_enabled
@test "terminator::myjournal::autocreate_enabled enabled-with-TRUE" {
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='TRUE'

  run terminator::myjournal::autocreate_enabled

  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::autocreate_enabled
@test "terminator::myjournal::autocreate_enabled enabled-with-True" {
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='True'

  run terminator::myjournal::autocreate_enabled

  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_success
}

# bats test_tags=terminator::myjournal,terminator::myjournal::autocreate_enabled
@test "terminator::myjournal::autocreate_enabled off-with-other-value" {
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='yes'

  run terminator::myjournal::autocreate_enabled

  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_failure
}

################################################################################
# terminator::myjournal::invoke
################################################################################

# bats test_tags=terminator::myjournal,terminator::myjournal::invoke
@test "terminator::myjournal::invoke opens-existing-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  TERMINATOR_MYJOURNAL_DIR="${temp_dir}"
  mkdir -p "${temp_dir}/2025/12"
  printf -- '---\nexisting\n---\n' >"${temp_dir}/2025/12/11.md"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vim::invoke { echo "vim called: $*"; }

  run terminator::myjournal::invoke '2025/12/11'

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"

  assert_success
  assert_output --partial 'vim called'
  assert_output --partial '2025/12/11.md'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::invoke
@test "terminator::myjournal::invoke prompts-when-autocreate-off-and-file-missing" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_DIR="${temp_dir}"
  unset TERMINATOR_MYJOURNAL_AUTOCREATE

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::prompt::ask {
    echo "PROMPT:$*"
    return 0
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vim::invoke { echo "vim called: $*"; }

  run terminator::myjournal::invoke '2025/12/11'

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"
  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_success
  assert_output --partial 'PROMPT:Create new journal entry at'
  [[ -f "${temp_dir}/2025/12/11.md" ]]
  assert_output --partial 'vim called'
  assert_output --partial '2025/12/11.md'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::invoke
@test "terminator::myjournal::invoke skips-missing-when-prompt-declined" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_DIR="${temp_dir}"
  unset TERMINATOR_MYJOURNAL_AUTOCREATE

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::prompt::ask {
    echo "PROMPT:$*"
    return 1
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vim::invoke { echo "vim called: $*"; }

  run terminator::myjournal::invoke '2025/12/11'

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"
  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_failure
  assert_output --partial 'PROMPT:Create new journal entry at'
  [[ ! -f "${temp_dir}/2025/12/11.md" ]]
  refute_output --partial 'vim called'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::invoke
@test "terminator::myjournal::invoke autocreates-without-prompting-when-enabled" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  TERMINATOR_MYJOURNAL_DIR="${temp_dir}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='1'

  # Prompt declines; autocreate must bypass it entirely.
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::prompt::ask {
    echo "PROMPT:$*"
    return 1
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vim::invoke { echo "vim called: $*"; }

  run terminator::myjournal::invoke '2025/12/11'

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"
  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"

  assert_success
  [[ -f "${temp_dir}/2025/12/11.md" ]]
  assert_output --partial 'vim called'
  assert_output --partial '2025/12/11.md'
  refute_output --partial 'PROMPT:'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::myjournal,terminator::myjournal::invoke
@test "terminator::myjournal::invoke aborts-when-autocreate-fails" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_dir="${TERMINATOR_MYJOURNAL_DIR}"
  local original_autocreate="${TERMINATOR_MYJOURNAL_AUTOCREATE:-}"
  # Point the journal root at a read-only dir so new_entry cannot create the file.
  local readonly_dir="${temp_dir}/locked"
  mkdir -p "${readonly_dir}"
  chmod 000 "${readonly_dir}"
  TERMINATOR_MYJOURNAL_DIR="${readonly_dir}"
  TERMINATOR_MYJOURNAL_AUTOCREATE='1'

  # If a failed autocreate fell through to the prompt, this would fire.
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::prompt::ask {
    echo "PROMPT:$*"
    return 1
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vim::invoke { echo "vim called: $*"; }

  run terminator::myjournal::invoke '2025/12/11'

  TERMINATOR_MYJOURNAL_DIR="${original_dir}"
  TERMINATOR_MYJOURNAL_AUTOCREATE="${original_autocreate}"
  chmod 755 "${readonly_dir}"

  assert_failure
  refute_output --partial 'PROMPT:'
  refute_output --partial 'vim called'

  rm -rf "${temp_dir}"
}
