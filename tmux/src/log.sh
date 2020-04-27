#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/log.sh"

function tmux::log::path() {
  # TMUX=/private/tmp/tmux-501/default,66097,0
  echo "/tmp/tmux-session.$$.log"
}

function tmux::log::debug() {
  local caller_level=3
  tmux::log::file::debug -c "${caller_level}" "$@"
  tmux::log::console::debug -c "${caller_level}" "$@"
}

function tmux::log::info() {
  local caller_level=3
  tmux::log::file::info -c "${caller_level}" "$@"
  tmux::log::console::info -c "${caller_level}" "$@"
}

function tmux::log::warning() {
  local caller_level=3
  tmux::log::file::warning -c "${caller_level}" "$@"
  tmux::log::console::warning -c "${caller_level}" "$@"
}

function tmux::log::error() {
  local caller_level=3
  tmux::log::file::error -c "${caller_level}" "$@"
  tmux::log::console::error -c "${caller_level}" "$@"
}

function tmux::log::console::debug() {
  terminator::log::debug "$@"
}

function tmux::log::console::info() {
  terminator::log::info "$@"
}

function tmux::log::console::warning() {
  terminator::log::warning "$@"
}

function tmux::log::console::error() {
  terminator::log::error "$@"
}

function tmux::log::file::debug() {
  terminator::log::debug -o "$(tmux::log::path)" "$@"
}

function tmux::log::file::info() {
  terminator::log::info -o "$(tmux::log::path)" "$@"
}

function tmux::log::file::warning() {
  terminator::log::warning -o "$(tmux::log::path)" "$@"
}

function tmux::log::file::error() {
  terminator::log::error -o "$(tmux::log::path)" "$@"
}
