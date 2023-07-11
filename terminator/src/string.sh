#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/number.sh"

terminator::__pragma__::once || return 0

function terminator::string::bytes_to_length_offset() {
  local value \
    length \
    offset \
    output \
    help_command=terminator::string::byte_to_length::usage

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        "${help_command}"
        return 0
        ;;
      -v | --value)
        shift
        value="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        "${help_command}"
        return 1
        ;;
      *)
        if [[ -z "${output}" ]]; then
          output="$1"
        fi
        ;;
    esac
    shift
  done

  length="${#value}"

  local LANG=C LC_ALL=C # converts bash length calculation to bytes

  offset="$(( ${#value} - length ))"

  if [[ -n "${output}" ]]; then
    printf -v "${output}" '%s' "${offset}"
    return
  fi

  printf '%s' "${offset}"
}

function terminator::string::bytes_to_length_offset::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [ouput variable]

  -v, --value        String value to calculate number of bytes to length offset
                     If mutli-byte characters exist the ouput will be greater than 0.

  -o, --output       Variable to write output to.
                     Will use argument if specified and if flag is not used.
                     If not specified will write output to stdout

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::string::repeat() {
  local value \
    count \
    output_buffer \
    output \
    help_command=terminator::string::repeat::usage

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        "${help_command}"
        return 0
        ;;
      -c | --count)
        shift
        count="$1"
        ;;
      -v | --value)
        shift
        value="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        "${help_command}"
        return 1
        ;;
      *)
        if [[ -z "${output}" ]]; then
          output="$1"
        fi
        ;;
    esac
    shift
  done

  if ! terminator::number::is_unsigned_integer "${count}"; then
    >&2 printf "ERROR: %s invalid count: '%s' is not an unsigned integer\n" \
        "${FUNCNAME[0]}" \
        "${count}"
    "${help_command}"
    return 1
  fi

  for (( index = 0; index < count; index++ )); do
    output_buffer="${output_buffer}${value}"
  done

  if [[ -n "${output}" ]]; then
    printf -v "${output}" '%s' "${output_buffer}"
    return
  fi

  printf '%s' "${output_buffer}"
}


function terminator::string::repeat::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [ouput variable]

  -v, --value        String value to repeat
                     Will not print anything if empty

  -c, --count        Number of times to repeat the string
                     Must be valid unsigned integer.

  -o, --output       Variable to write output to.
                     Will use argument if specified and if flag is not used.
                     If not specified will write output to stdout

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::string::strip_colors() {
  local value \
    output_buffer \
    output \
    help_command=terminator::string::strip_colors::usage

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        "${help_command}"
        return 0
        ;;
      -v | --value)
        shift
        value="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        "${help_command}"
        return 1
        ;;
      *)
        if [[ -z "${output}" ]]; then
          output="$1"
        fi
        ;;
    esac
    shift
  done

  output_buffer="$(sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g' <<< "${value}" | sed 's/\\\[//g' | sed 's/\\\]//g')"

  if [[ -n "${output}" ]]; then
    printf -v "${output}" '%s' "${output_buffer}"
    return
  fi

  printf '%s' "${output_buffer}"
}

function terminator::string::strip_colors::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [ouput variable]

  -v, --value        String value to remove color codes from

  -o, --output       Variable to write output to.
                     Will use argument if specified and if flag is not used.
                     If not specified will write output to stdout

  -h, --help         Display this help message
USAGE_TEXT
}
