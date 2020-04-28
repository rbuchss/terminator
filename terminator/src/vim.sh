#!/bin/bash

function terminator::vim::open::filename_match() {
  # shellcheck disable=SC2046
  vim -p $(ag -g "$1" "${2:-./}")
}

function terminator::vim::open::content_match() {
  # shellcheck disable=SC2046
  vim -p $(ag -l "$1" "${2:-./}")
}

function terminator::vim::open::git_diff() {
  # shellcheck disable=SC2046
  vim -p $(git diff --name-only "$1")
}
