#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/styles.sh"

function terminator::prompt::git() {
  if ! command -v git > /dev/null 2>&1 \
    || ! command -v __git_ps1 > /dev/null 2>&1; then
    echo ''
    return 0
  fi

  local inside_worktree branch branch_symbol color status_symbol
  local color_off
  color_off="$(terminator::color::off)"

  if inside_worktree="$(git rev-parse --is-inside-work-tree 2>/dev/null)"; then
    branch="$(__git_ps1 '%s')"
    branch_symbol="$(terminator::styles::branch_symbol)"

    if [[ "${branch}" =~ ^\( ]]; then
      branch_symbol="$(terminator::styles::detached_head_symbol)"
    fi

    if [[ "${inside_worktree}" != 'true' ]]; then
      echo "${branch_symbol} ${branch}${color_off}"
      return 0
    fi

    if [[ -z "$(git status --porcelain)" ]]; then
      # Clean repository - nothing to commit
      color="$(terminator::styles::ok_color)"
      status_symbol="$(terminator::styles::ok_symbol)"
    elif ! (git diff --no-ext-diff --cached --quiet --exit-code \
      && git diff --no-ext-diff --quiet --exit-code); then
      # Changes exist on working tree
      color="$(terminator::styles::error_color)"
      status_symbol="$(terminator::styles::error_symbol)"
    else
      # Untracked files exist
      color="$(terminator::color::code '38;5;214m')"
      status_symbol="$(terminator::styles::warning_symbol)"
    fi

    echo "${color}${branch_symbol} ${branch} ${status_symbol}${color_off}"
    return 0
  fi

  echo ''
}
