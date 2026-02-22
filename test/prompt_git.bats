#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/prompt/git.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::prompt::git::format
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format clean-branch" {
  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial 'main'
  # upstream same symbol
  assert_output --partial '≡'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-ahead" {
  run terminator::prompt::git::format \
    'feature' \
    'origin/feature' \
    3 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial 'feature'
  assert_output --partial '↑3'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-behind" {
  run terminator::prompt::git::format \
    'feature' \
    'origin/feature' \
    0 \
    2 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial 'feature'
  assert_output --partial '↓2'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-ahead-and-behind" {
  run terminator::prompt::git::format \
    'feature' \
    'origin/feature' \
    3 \
    2 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial 'feature'
  assert_output --partial '↑3'
  assert_output --partial '↓2'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-gone-upstream" {
  run terminator::prompt::git::format \
    'feature' \
    'origin/feature' \
    0 \
    0 \
    'gone' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial 'feature'
  assert_output --partial 'x'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-no-upstream" {
  run terminator::prompt::git::format \
    'feature' \
    '' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial 'feature'
  # No upstream indicators
  refute_output --partial '≡'
  refute_output --partial '↑'
  refute_output --partial '↓'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-index-changes" {
  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    2 3 1 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial '+2'
  assert_output --partial '~3'
  assert_output --partial '-1'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-working-tree-changes" {
  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    1 2 0 0 \
    0

  assert_success
  assert_output --partial '+1'
  assert_output --partial '~2'
  # Divider should NOT be present (no index changes)
  refute_output --partial '|'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-index-and-working-tree-changes" {
  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    1 0 0 0 \
    0 1 0 0 \
    0

  assert_success
  # Divider should be present (both index and working tree changes)
  assert_output --partial '|'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-unmerged-index" {
  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 2 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial '!2'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-unmerged-files" {
  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 3 \
    0

  assert_success
  assert_output --partial '!3'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-stash-enabled" {
  local original="${TERMINATOR_GIT_STATUS_STASH_ENABLED}"
  TERMINATOR_GIT_STATUS_STASH_ENABLED=1

  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    5

  TERMINATOR_GIT_STATUS_STASH_ENABLED="${original}"

  assert_success
  assert_output --partial '#5'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-stash-disabled" {
  local original="${TERMINATOR_GIT_STATUS_STASH_ENABLED}"
  TERMINATOR_GIT_STATUS_STASH_ENABLED=0

  run terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    5

  TERMINATOR_GIT_STATUS_STASH_ENABLED="${original}"

  assert_success
  refute_output --partial '#5'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-detached-head" {
  run terminator::prompt::git::format \
    '(abc1234...)' \
    '' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial '(abc1234...)'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format with-output-variable" {
  local result=''

  terminator::prompt::git::format \
    'main' \
    'origin/main' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0 \
    result

  [[ -n "${result}" ]]
  [[ "${result}" == *'main'* ]]
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format compact-ahead-and-behind" {
  local original="${TERMINATOR_GIT_STATUS_BRANCH_BEHIND_AND_AHEAD}"
  TERMINATOR_GIT_STATUS_BRANCH_BEHIND_AND_AHEAD='compact'

  run terminator::prompt::git::format \
    'feature' \
    'origin/feature' \
    3 \
    2 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  TERMINATOR_GIT_STATUS_BRANCH_BEHIND_AND_AHEAD="${original}"

  assert_success
  assert_output --partial '↕'
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::format
@test "terminator::prompt::git::format enclosure-brackets" {
  run terminator::prompt::git::format \
    'main' \
    '' \
    0 \
    0 \
    '' \
    0 0 0 0 \
    0 0 0 0 \
    0

  assert_success
  assert_output --partial '['
  assert_output --partial ']'
}

################################################################################
# terminator::prompt::git::branch
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-empty-git-dir" {
  run terminator::prompt::git::branch ''

  assert_failure 1
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-HEAD-ref" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'ref: refs/heads/my-branch' >"${temp_dir}/HEAD"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output 'my-branch'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-detached-HEAD" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'abc1234567890abcdef1234567890abcdef123456' >"${temp_dir}/HEAD"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output '(abc1234...)'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-output-variable" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'ref: refs/heads/feature' >"${temp_dir}/HEAD"

  local result=''
  terminator::prompt::git::branch "${temp_dir}" result

  assert_equal "${result}" 'feature'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-MERGE_HEAD" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'ref: refs/heads/main' >"${temp_dir}/HEAD"
  touch "${temp_dir}/MERGE_HEAD"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial 'main'
  assert_output --partial '|MERGING'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-CHERRY_PICK_HEAD" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'ref: refs/heads/main' >"${temp_dir}/HEAD"
  touch "${temp_dir}/CHERRY_PICK_HEAD"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial 'main'
  assert_output --partial '|CHERRY-PICKING'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-REVERT_HEAD" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'ref: refs/heads/main' >"${temp_dir}/HEAD"
  touch "${temp_dir}/REVERT_HEAD"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial 'main'
  assert_output --partial '|REVERTING'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-BISECT_LOG" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}"

  echo 'ref: refs/heads/main' >"${temp_dir}/HEAD"
  touch "${temp_dir}/BISECT_LOG"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial 'main'
  assert_output --partial '|BISECTING'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-rebase-merge" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/rebase-merge"

  echo 'refs/heads/rebasing-branch' >"${temp_dir}/rebase-merge/head-name"
  echo '3' >"${temp_dir}/rebase-merge/msgnum"
  echo '7' >"${temp_dir}/rebase-merge/end"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial 'rebasing-branch'
  assert_output --partial '|REBASE'
  assert_output --partial '3/7'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-rebase-apply-rebasing" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/rebase-apply"

  echo 'refs/heads/apply-branch' >"${temp_dir}/rebase-apply/head-name"
  echo '2' >"${temp_dir}/rebase-apply/next"
  echo '5' >"${temp_dir}/rebase-apply/last"
  touch "${temp_dir}/rebase-apply/rebasing"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial 'apply-branch'
  assert_output --partial '|REBASE'
  assert_output --partial '2/5'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-rebase-apply-am" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/rebase-apply"

  echo 'ref: refs/heads/main' >"${temp_dir}/HEAD"
  echo '1' >"${temp_dir}/rebase-apply/next"
  echo '3' >"${temp_dir}/rebase-apply/last"
  touch "${temp_dir}/rebase-apply/applying"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial '|AM'
  assert_output --partial '1/3'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::branch
@test "terminator::prompt::git::branch with-rebase-apply-unknown" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/rebase-apply"

  echo 'ref: refs/heads/main' >"${temp_dir}/HEAD"
  echo '1' >"${temp_dir}/rebase-apply/next"
  echo '2' >"${temp_dir}/rebase-apply/last"

  run terminator::prompt::git::branch "${temp_dir}"

  assert_success
  assert_output --partial '|AM/REBASE'
  assert_output --partial '1/2'

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::prompt::git::stash
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::stash
@test "terminator::prompt::git::stash with-stash-log" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/logs/refs"

  printf 'stash1\nstash2\nstash3\n' >"${temp_dir}/logs/refs/stash"

  run terminator::prompt::git::stash "${temp_dir}"

  assert_success
  assert_output '3'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::stash
@test "terminator::prompt::git::stash with-empty-stash-log" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/logs/refs"

  : >"${temp_dir}/logs/refs/stash"

  run terminator::prompt::git::stash "${temp_dir}"

  assert_success
  assert_output '0'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::stash
@test "terminator::prompt::git::stash with-output-variable" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  mkdir -p "${temp_dir}/logs/refs"

  printf 'stash1\nstash2\n' >"${temp_dir}/logs/refs/stash"

  local result=''
  terminator::prompt::git::stash "${temp_dir}" result

  assert_equal "${result}" '2'

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::stash
@test "terminator::prompt::git::stash with-no-stash-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  # No stash file - fallback to git stash list
  # In a non-git directory, git stash list returns empty

  run terminator::prompt::git::stash "${temp_dir}"

  assert_success
  # Should be 0 (no stash entries, wc -l of empty output)

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::prompt::git::status
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status clean-repo" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success
  # First line should be the branch name
  local branch
  branch="$(echo "${output}" | head -1)"
  [[ -n "${branch}" ]]

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status with-modified-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  # Modify a tracked file
  echo 'modified' >"${temp_dir}/file.txt"

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status with-staged-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  # Stage a modification
  echo 'staged' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status with-untracked-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  # Add an untracked file
  echo 'new' >"${temp_dir}/untracked.txt"

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status with-deleted-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  # Delete a tracked file
  rm "${temp_dir}/file.txt"

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status with-staged-new-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  # Stage a new file (added to index)
  echo 'new' >"${temp_dir}/new.txt"
  git -C "${temp_dir}" add new.txt

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git::status
@test "terminator::prompt::git::status initial-commit" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"

  local git_dir="${temp_dir}/.git"

  run terminator::prompt::git::status "${git_dir}" 'true'

  assert_success

  rm -rf "${temp_dir}"
}

################################################################################
# terminator::prompt::git
################################################################################

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git
@test "terminator::prompt::git in-git-repo" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  local original_dir
  original_dir="$(pwd)"
  cd "${temp_dir}" || return 1

  local result=''
  terminator::prompt::git result

  cd "${original_dir}" || return 1

  [[ -n "${result}" ]]
  [[ "${result}" == *'['* ]]
  [[ "${result}" == *']'* ]]

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git
@test "terminator::prompt::git not-in-git-repo" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  local original_dir
  original_dir="$(pwd)"
  cd "${temp_dir}" || return 1

  run terminator::prompt::git

  cd "${original_dir}" || return 1

  assert_success
  assert_output ''

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::prompt,terminator::prompt::git,terminator::prompt::git
@test "terminator::prompt::git inside-git-dir" {
  local temp_dir
  temp_dir="$(mktemp -d)"

  git init "${temp_dir}" >/dev/null 2>&1
  git -C "${temp_dir}" config user.email "test@test.com"
  git -C "${temp_dir}" config user.name "Test"
  echo 'initial' >"${temp_dir}/file.txt"
  git -C "${temp_dir}" add file.txt
  git -C "${temp_dir}" commit -m 'initial' >/dev/null 2>&1

  local original_dir
  original_dir="$(pwd)"
  cd "${temp_dir}/.git" || return 1

  local result=''
  terminator::prompt::git result

  cd "${original_dir}" || return 1

  [[ -n "${result}" ]]
  [[ "${result}" == *'GIT_DIR!'* ]]

  rm -rf "${temp_dir}"
}
