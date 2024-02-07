#!/bin/bash
# shellcheck disable=SC2317

SEARCH_DIRS=(terminator)
DEFAULT_OUTPUT=/dev/stdout

write_exports_to_file="${1:-false}"

__repo_root__() {
  git rev-parse --show-toplevel
}

find_and_format_with_function_prefix() {
  # With function prefix eg:
  #   function foo {
  #     ...
  #   }
  #
  #   function bar() {
  #     ...
  #   }
  #
  #   function qux () {
  #     ...
  #   }
  local \
    file="${1:?}" \
    write_exports_to_file="${2:-false}" \
    output="${3:-/dev/stdout}"

  find_and_format \
    "${file}" \
    '^function +([^(){} =]+) *(\(\))? *\{?$' \
    's/^function +([^(){} =]+) *(\(\))? *\{?$/export -f \1/' \
    "${write_exports_to_file}" \
    "${output}"
}

find_and_format_without_function_prefix() {
  # Without function prefix eg:
  #   foo() {
  #     ...
  #   }
  #
  #   bar () {
  #     ...
  #   }
  local \
    file="${1:?}" \
    write_exports_to_file="${2:-false}" \
    output="${3:-/dev/stdout}"

  find_and_format \
   "${file}" \
    '^([^(){} =]+) *\(\) *\{?$' \
    's/^([^(){} =]+) *\(\) *\{?$/export -f \1/' \
    "${write_exports_to_file}" \
    "${output}"
}

find_and_format() {
  local \
    file="${1:?}" \
    find_pattern="${2:?}" \
    replace_pattern="${3:?}" \
    write_exports_to_file="${4:-false}" \
    output="${5:-/dev/stdout}" \
    all_functions_output \
    missing_functions_output \
    line

  all_functions_output="$(mktemp /tmp/terminator-all-function-exports.XXXXXXXXXX)"
  missing_functions_output="$(mktemp /tmp/terminator-missing-function-exports.XXXXXXXXXX)"

  grep -E "${find_pattern}" "${file}" \
    | grep -v '__' \
    | sed -E "${replace_pattern}" \
    >> "${all_functions_output}"

  while IFS= read -r line; do
    if ! grep "^ *${line} *$" "${file}" > /dev/null 2>&1; then
      echo "# ${line}" >> "${missing_functions_output}"
    fi
  done < "${all_functions_output}"

  if [[ "${write_exports_to_file}" == 'true' ]]; then
    output="${file}"
  elif [[ -s "${missing_functions_output}" ]]; then
    echo "==> ${file} <=="
  fi

  cat "${missing_functions_output}" >> "${output}"

  if [[ -s "${missing_functions_output}" ]]; then
    return 1
  fi

  return 0
}

export -f find_and_format_with_function_prefix
export -f find_and_format_without_function_prefix
export -f find_and_format

repo_root="$(__repo_root__)"
found_missing_files=0

if [[ "${write_exports_to_file}" != 'true' ]]; then
  echo '################################################################################'
  echo '# Missing function exports to add:'
  echo '################################################################################'
fi

for search_dir in "${SEARCH_DIRS[@]}"; do
  find "${repo_root}/${search_dir}" -type f \( -name '*.sh' -or -name '*.bash' \) -print0 \
    | sort -z \
    | xargs -0 -I {} bash -c "find_and_format_with_function_prefix {} '${write_exports_to_file}' '${DEFAULT_OUTPUT}'" \
    || found_missing_files="$?"

  find "${repo_root}/${search_dir}" -type f \( -name '*.sh' -or -name '*.bash' \) -print0 \
    | sort -z \
    | xargs -0 -I {} bash -c "find_and_format_without_function_prefix {} '${write_exports_to_file}' '${DEFAULT_OUTPUT}'" \
    || found_missing_files="$?"
done

export -fn find_and_format_with_function_prefix
export -fn find_and_format_without_function_prefix
export -fn find_and_format

[[ "${write_exports_to_file}" != 'true' ]] && exit "${found_missing_files}"
