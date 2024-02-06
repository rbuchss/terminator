#!/usr/bin/env bash

THRESHOLD_ALL="${THRESHOLD_ALL:-80}"
THRESHOLD_NEW="${THRESHOLD_NEW:-90}"
THRESHOLD_MODIFIED="${THRESHOLD_MODIFIED:-0}"

STATUS_OK_SYMBOL=✅
STATUS_NOT_OK_SYMBOL=❌
PASS_SYMBOL=🟢
FAIL_SYMBOL=🔴

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"

COVERAGE_FILE=coverage/bats/coverage.json

if ! command -v jq > /dev/null 2>&1; then
  >&2 echo 'ERROR: jq not installed - skipping coverage report generation'
  exit 1
fi

function terminator::test::coverage::repo_root() {
  git rev-parse --show-toplevel
}

function terminator::test::coverage::get_overall_status() {
  local \
    coverage_report_input="${1:?}" \
    threshold="${2:-${THRESHOLD_ALL}}"

  jq -r \
    --arg threshold "${threshold}" \
    --arg pass_symbol "${STATUS_OK_SYMBOL}" \
    --arg fail_symbol "${STATUS_NOT_OK_SYMBOL}" \
    -f "${SCRIPT_DIR}/get_overall_status.jq" \
    < "${coverage_report_input}"
}

function terminator::test::coverage::get_overall_report() {
  local \
    coverage_report_input="${1:?}" \
    threshold="${2:-${THRESHOLD_ALL}}"

  cat <<EOF
| Lines | Covered | Coverage | Threshold | Status |
| :---: | :-----: | :------: | :-------: | :----: |
EOF

  jq -r \
    --arg threshold "${threshold}" \
    --arg pass_symbol "${PASS_SYMBOL}" \
    --arg fail_symbol "${FAIL_SYMBOL}" \
    -f "${SCRIPT_DIR}/get_overall_report.jq" \
    < "${coverage_report_input}"
}

function terminator::test::coverage::get_files_report() {
  local \
    coverage_report_input="${1:?}" \
    threshold="${2:?}" \
    coverage_report_output \
    repo_root \
    files_json='' \
    file \
    files=("${@:3}")

  coverage_report_output="$(mktemp /tmp/terminator-coverage-report.XXXXXXXXXX)"

  for file in "${files[@]}"; do
    if [[ -z "${files_json}" ]]; then
      files_json="\"${file}\""
    else
      files_json="${files_json}, \"${file}\""
    fi
  done

  repo_root="$(terminator::test::coverage::repo_root)"

  jq -r \
    --argjson files "[${files_json}]" \
    --arg base_path "${repo_root}" \
    --arg threshold "${threshold}" \
    --arg pass_symbol "${PASS_SYMBOL}" \
    --arg fail_symbol "${FAIL_SYMBOL}" \
    -f "${SCRIPT_DIR}/get_files_report.jq" \
    < "${coverage_report_input}" \
    > "${coverage_report_output}"

  if [[ -s "${coverage_report_output}" ]]; then
    cat <<EOF
| File | Lines | Covered | Coverage | Threshold | Status |
| :--- | :---: | :-----: | :------: | :-------: | :----: |
EOF
    cat "${coverage_report_output}"
    return 0
  fi

  # No files in filter found
  return 1
}

function terminator::test::coverage::get_new_files_report() {
  local \
    base_sha="${1:?}" \
    head_sha="${2:?}" \
    coverage_report_input="${3:?}" \
    threshold="${4:-${THRESHOLD_NEW}}" \
    file \
    new_files=()

  while IFS='' read -r file; do
    new_files+=("${file}")
  done < <(git diff --name-only --diff-filter=A "${base_sha}" "${head_sha}")

  terminator::test::coverage::get_files_report "${coverage_report_input}" "${threshold}" "${new_files[@]}" \
    || echo 'No new covered files...'
}

function terminator::test::coverage::get_modified_files_report() {
  local \
    base_sha="${1:?}" \
    head_sha="${2:?}" \
    coverage_report_input="${3:?}" \
    threshold="${4:-${THRESHOLD_MODIFIED}}" \
    file \
    modified_files=()

  while IFS='' read -r file; do
    modified_files+=("${file}")
  done < <(git diff --name-only --diff-filter=CMRT "${base_sha}" "${head_sha}")

  terminator::test::coverage::get_files_report "${coverage_report_input}" "${threshold}" "${modified_files[@]}" \
    || echo 'No modified covered files...'
}

function terminator::test::coverage::format_pull_request_comment() {
  local \
    base_sha="${1:?}" \
    head_sha="${2:?}" \
    current_status="${3:?}" \
    overall_report="${4:?}" \
    new_files_report="${5:?}" \
    modified_files_report="${6:?}" \
    report_base \
    report_head

  report_base="$(git rev-parse --verify "${base_sha}")"

  if [[ "${report_base}" == "${base_sha}" ]]; then
    report_base="${report_base:0:7}"
  else
    report_base="${base_sha}"
  fi

  report_head="$(git rev-parse --verify "${head_sha}")"

  if [[ "${report_head}" == "${head_sha}" ]]; then
    report_head="${report_head:0:7}"
  else
    report_head="${head_sha}"
  fi

  cat <<EOF
# ☂️ Shell Cov
> current status: ${current_status}
## Overall Coverage
${overall_report}
## New Files
${new_files_report}
## Modified Files
${modified_files_report}

> updated for commit range: \`${report_base}..${report_head}\` by 🐢
EOF

}

function terminator::test::coverage::generate_pull_request_comment() {
  local \
    base_sha="${1:?}" \
    head_sha="${2:?}" \
    coverage_report_output="${3:-/dev/stdout}" \
    coverage_report_input="${4:-${COVERAGE_FILE}}" \
    coverage_report_temp_output \
    current_status \
    overall_report \
    new_files_report \
    modified_files_report

  if ! git rev-parse --verify "${base_sha}" > /dev/null 2>&1; then
    >&2 echo "ERROR: invalid base ref: '${base_sha}'"
    return 1
  fi

  if ! git rev-parse --verify "${head_sha}" > /dev/null 2>&1; then
    >&2 echo "ERROR: invalid head ref: '${head_sha}'"
    return 1
  fi

  coverage_report_input="$(terminator::test::coverage::repo_root)/${coverage_report_input}"
  current_status="$(terminator::test::coverage::get_overall_status "${coverage_report_input}" "${THRESHOLD_ALL}")"
  overall_report="$(terminator::test::coverage::get_overall_report "${coverage_report_input}" "${THRESHOLD_ALL}")"

  new_files_report="$( \
    terminator::test::coverage::get_new_files_report \
      "${base_sha}" \
      "${head_sha}" \
      "${coverage_report_input}" \
      "${THRESHOLD_NEW}" \
    )"

  modified_files_report="$( \
    terminator::test::coverage::get_modified_files_report \
      "${base_sha}" \
      "${head_sha}" \
      "${coverage_report_input}" \
      "${THRESHOLD_MODIFIED}" \
    )"

  coverage_report_temp_output="$(mktemp /tmp/terminator-coverage-report.XXXXXXXXXX)"

  terminator::test::coverage::format_pull_request_comment \
    "${base_sha}" \
    "${head_sha}" \
    "${current_status}" \
    "${overall_report}" \
    "${new_files_report}" \
    "${modified_files_report}" \
    > "${coverage_report_temp_output}"

  if [[ "${coverage_report_output}" == 'GITHUB_OUTPUT' ]]; then
    echo "Using GITHUB_OUTPUT: ${GITHUB_OUTPUT}"

    # Note for multiline strings we need to use the following format:
    #
    #   {name}<<{delimiter}
    #   {value}
    #   {delimiter}
    #
    # ref: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings

    # Using a random string as a delimiter
    local github_delimiter
    github_delimiter="$(dd if=/dev/urandom bs=15 count=1 status=none | base64)"

    # We use awk to convert linebreaks into \n literals to pass downstream
    # otherwise we run into quoting issues with github-script bodies.
    cat >> "${GITHUB_OUTPUT}" <<EOF
coverage_report<<${github_delimiter}
$(awk -v ORS='\\n' '1' "${coverage_report_temp_output}")
${github_delimiter}
EOF

    return
  fi

  cat "${coverage_report_temp_output}" > "${coverage_report_output}"
}

terminator::test::coverage::generate_pull_request_comment "$@"
