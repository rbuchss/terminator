#!/bin/bash

function terminator::file::extract() {
  for file in "$@"; do
    if [[ ! -f "${file}" ]]; then
      >&2 echo "ERROR: ${FUNCNAME[0]}: '${file}' is not a valid file"
      return 1
    fi

    case "${file}" in
      *.tar.bz2) tar xvjf "${file}" ;;
      *.tar.gz) tar xvzf "${file}" ;;
      *.bz2) bunzip2 "${file}" ;;
      *.rar) unrar x "${file}" ;;
      *.gz) gunzip "${file}" ;;
      *.tar) tar xvf "${file}" ;;
      *.tbz2) tar xvjf "${file}" ;;
      *.tgz) tar xvzf "${file}" ;;
      *.zip) unzip "${file}" ;;
      *.Z) uncompress "${file}" ;;
      *.7z) 7z x "${file}" ;;
      *)
        >&2 echo "ERROR: ${FUNCNAME[0]} '${file}' cannot be extracted"
        >&2 echo "'${file##*.}' is an unsupported format"
        return 1
        ;;
    esac
  done
}

# Creates an archive from given directory
function terminator::file::mktar() {
  tar cvf  "${1%%/}.tar"   "${1%%/}/"
}

function terminator::file::mktgz() {
  tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"
}

function terminator::file::mktbz() {
  tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"
}

function terminator::file::swap() {
  if (( $# != 2 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: 2 arguments required"
    return 1
  fi
  if [[ ! -e "$1" ]]; then
    >&2 echo "ERROR: ${FUNCNAME[0]}: '$1' does not exist"
    return 1
  fi
  if [[ ! -e "$2" ]]; then
    >&2 echo "ERROR: ${FUNCNAME[0]}: '$2' does not exist"
    return 1
  fi

  local temp_file="tmp.$$"
  mv "$1" "${temp_file}"
  mv "$2" "$1"
  mv "${temp_file}" "$2"
}

# finds all files and dirs in the pwd that have spaces in their name
# and renames them with all spaces converted to _
function terminator::file::nuke_spaces() {
  ruby -e 'files = Dir["./*"].select { |file| file.match(/ /) }
    files.each do |file|
      newname = file.gsub(/ /, "_")
      puts "nuke_spaces: #{file} --> #{newname}"
      File.rename(file, newname)
    end'
}

# Find a file from pwd with pattern $1 in name and Execute $2 on it
function terminator::file::find_exec() {
  if (( $# != 2 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invaild # of args"
    >&2 echo "Usage: ${FUNCNAME[0]} pattern command"
    return 1
  fi

  find . -type f -iname '*'"$1"'*' -exec "${2:-file}" {} \; ;
}

function terminator::file::dirsize_big() {
  dir="${1:-.}"
  dir="${dir%%+(/)}"

  terminator::file::dirsize "${dir}" \
    | grep -E '^ *[0-9.]*[MGTPEZY].'
}

function terminator::file::dirsize() {
  dir="${1:-.}"
  dir="${dir%%+(/)}"
  cache="/tmp/dirsize-list.$$"

  du -shx "${dir}"/* 2>/dev/null \
    | sort -n > "${cache}"
  # Units are K,M,G,T,P,E,Z,Y
  grep -E '^ *[0-9.]*[^KMGTPEZY]\s+' "${cache}"
  grep -E '^ *[0-9.]*K' "${cache}"
  grep -E '^ *[0-9.]*M' "${cache}"
  grep -E '^ *[0-9.]*G' "${cache}"
  grep -E '^ *[0-9.]*T' "${cache}"
  grep -E '^ *[0-9.]*P' "${cache}"
  grep -E '^ *[0-9.]*E' "${cache}"
  grep -E '^ *[0-9.]*Z' "${cache}"
  grep -E '^ *[0-9.]*Y' "${cache}"
  rm -f "${cache}"
}

function terminator::file::mkcd() {
  mkdir -p "$1" && cd "$1" || return 1
}
