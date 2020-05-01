#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/styles.sh"

function terminator::prompt::git::old() {
  local inside_worktree

  if ! command -v git > /dev/null 2>&1 \
    || ! command -v __git_ps1 > /dev/null 2>&1 \
    || ! inside_worktree="$(git rev-parse --is-inside-work-tree 2>/dev/null)"; then
    echo ''
    return 0
  fi

  local branch branch_symbol color status_symbol color_off

  branch="$(__git_ps1 '%s')"
  branch_symbol="$(terminator::styles::branch_symbol)"
  color_off="$(terminator::color::off)"

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
}

function terminator::prompt::git() {
  local repo_info
  if ! command -v git > /dev/null 2>&1 \
    || ! repo_info="$(git rev-parse \
    --git-dir \
    --is-inside-git-dir \
    --is-bare-repository \
    --is-inside-work-tree 2>/dev/null)" \
    || [[ -z "${repo_info}" ]]; then
      return 0
  fi

  local inside_worktree="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  local bare_repo="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  local inside_gitdir="${repo_info##*$'\n'}"
  local gitdir="${repo_info%$'\n'*}"

  # echo "inside_worktree: ${inside_worktree}"
  # echo "bare_repo: ${bare_repo}"
  # echo "inside_gitdir: ${inside_gitdir}"
  # echo "gitdir: ${gitdir}"

  local response=()

  if [[ 'true' == "${inside_gitdir}" ]] && [[ 'true' != "${bare_repo}" ]]; then
    response+=('GIT_DIR!')
  elif [[ 'true' == "${inside_worktree}" ]]; then
    while IFS= read -r result; do
      response+=("${result}")
    done < <(terminator::prompt::git::status "${gitdir}")
  fi

  terminator::prompt::git::format "${response[@]}"
}

function terminator::prompt::git::status() {
  local gitdir="$1"

  local branch
  local upstream
  local ahead_by=0
  local behind_by=0
  local gone
  local index_added=()
  local index_modified=()
  local index_deleted=()
  local index_unmerged=()
  local files_added=()
  local files_modified=()
  local files_deleted=()
  local files_unmerged=()
  local stash_count=0

  local untracked_files_option='-uall' # TODO add option for this? '-uno' '-unormal'

  local index_and_working_regexp='^([^#])(.) ([^[:space:]]*)( -> (.*))?$'
  local branch_and_upstream_regexp='^## ([^[:space:].]+)(\.\.\.([^[:space:]]+))?( \[(ahead ([[:digit:]]+))?(, )?(behind ([[:digit:]]+))?(gone)?\])?$'
  local init_commit_regexp='^## Initial commit on ([^[:space:]]+)$'

  while IFS='' read -r stat; do
    if [[ "${stat}" =~ ${index_and_working_regexp} ]]; then
      local index="${BASH_REMATCH[1]}"
      local working="${BASH_REMATCH[2]}"
      local path="${BASH_REMATCH[3]}"

      case "${index}" in
        A) index_added+=("${path}") ;;
        M) index_modified+=("${path}") ;;
        R) index_modified+=("${path}") ;;
        C) index_modified+=("${path}") ;;
        D) index_deleted+=("${path}") ;;
        U) index_unmerged+=("${path}") ;;
      esac

      case "${working}" in
        \?) files_added+=("${path}") ;;
        A) files_added+=("${path}") ;;
        M) files_modified+=("${path}") ;;
        D) files_deleted+=("${path}") ;;
        U) files_unmerged+=("${path}") ;;
      esac

      continue
    fi

    if [[ "${stat}" =~ ${branch_and_upstream_regexp} ]]; then
      branch="${BASH_REMATCH[1]}"
      upstream="${BASH_REMATCH[3]}"
      ahead_by="${BASH_REMATCH[6]:-0}"
      behind_by="${BASH_REMATCH[9]:-0}"
      gone="${BASH_REMATCH[10]}"
      continue
    fi

    if [[ "${stat}" =~ ${init_commit_regexp} ]]; then
      branch="${BASH_REMATCH[1]}"
      continue
    fi
  done < <(git -c core.quotepath=false \
    -c color.status=false \
    status \
    --ignore-submodules=dirty \
    "${untracked_files_option}" \
    --short --branch 2>/dev/null)

  [[ -z "${branch}" ]] && branch="$(terminator::prompt::git::branch "${gitdir}")"

  # echo "branch: ${branch}"
  # echo "upstream: ${upstream}"
  # echo "ahead_by: ${ahead_by}"
  # echo "behind_by: ${behind_by}"
  # echo "gone: ${gone}"
  # echo "${#index_added[@]} index_added: ${index_added[*]}"
  # echo "${#index_modified[@]} index_modified: ${index_modified[*]}"
  # echo "${#index_deleted[@]} index_deleted: ${index_deleted[*]}"
  # echo "${#index_unmerged[@]} index_unmerged: ${index_unmerged[*]}"
  # echo "${#files_added[@]} files_added: ${files_added[*]}"
  # echo "${#files_modified[@]} files_modified: ${files_modified[*]}"
  # echo "${#files_deleted[@]} files_deleted: ${files_deleted[*]}"
  # echo "${#files_unmerged[@]} files_unmerged: ${files_unmerged[*]}"

  local response=(
    "${branch}"
    "${upstream}"
    "${ahead_by}"
    "${behind_by}"
    "${gone}"
    "${#index_added[@]}"
    "${#index_modified[@]}"
    "${#index_deleted[@]}"
    "${#index_unmerged[@]}"
    "${#files_added[@]}"
    "${#files_modified[@]}"
    "${#files_deleted[@]}"
    "${#files_unmerged[@]}"
  )
  printf '%s\n' "${response[@]}"
}

# shellcheck disable=SC2178,SC2128
function terminator::prompt::git::format() {
  local branch="$1"
  local upstream="$2"
  local ahead_by="$3"
  local behind_by="$4"
  local gone="$5"
  local index_added="$6"
  local index_modified="$7"
  local index_deleted="$8"
  local index_unmerged="$9"
  local files_added="${10}"
  local files_modified="${11}"
  local files_deleted="${12}"
  local files_unmerged="${13}"
  local stash_count="${14}"

  local branch_symbol
  branch_symbol="$(terminator::styles::branch_symbol)"

  local yellow_color green_color red_color cyan_color grey_color color_off
  green_color="$(terminator::color::code '0;92m' 'bare')"
  red_color="$(terminator::color::code '0;91m' 'bare')"
  yellow_color="$(terminator::color::code '0;93m' 'bare')"
  cyan_color="$(terminator::color::code '0;94m' 'bare')"
  grey_color="$(terminator::color::code '0;90m' 'bare')"
  color_off="$(terminator::color::code '0m' 'bare')"

  local upstream_message
  if [[ -n "${upstream}" ]]; then
    if [[ -n "${gone}" ]]; then
      upstream_message+=" ${red_color}x${color_off}"
    elif (( ahead_by == 0 && behind_by == 0 )); then
      upstream_message+=" ${grey_color}≡${color_off}"
    # elif (( ahead_by != 0 && behind_by != 0 )); then # TODO add flag to enable
    #   upstream_message=" ${ahead_by}↕${behind_by}"
    else
      (( ahead_by != 0 )) && upstream_message+=" ${green_color}↑${ahead_by}${color_off}"
      (( behind_by != 0 )) && upstream_message+=" ${red_color}↓${behind_by}${color_off}"
    fi
  fi

  local index_message
  if (( index_added != 0 )) \
    || (( index_modified != 0 )) \
    || (( index_deleted != 0 )) \
    || (( index_unmerged != 0 )); then
      index_message+="${green_color}"
      # (( index_added != 0 )) && index_message+=" +${index_added}"
      index_message+=" +${index_added}"
      # (( index_modified != 0 )) && index_message+=" ~${index_modified}"
      index_message+=" ~${index_modified}"
      # (( index_deleted != 0 )) && index_message+=" -${index_deleted}"
      index_message+=" -${index_deleted}"
      (( index_unmerged != 0 )) && index_message+=" !${index_unmerged}"
      index_message+="${color_off}"
  fi

  local files_message
  if (( files_added != 0 )) \
    || (( files_modified != 0 )) \
    || (( files_deleted != 0 )) \
    || (( files_unmerged != 0 )); then
      # add divider only if index message exists
      if (( index_added != 0 )) \
        || (( index_modified != 0 )) \
        || (( index_deleted != 0 )) \
        || (( index_unmerged != 0 )); then
          files_message+=" ${yellow_color}|${color_off}"
      fi
      files_message+="${red_color}"
      # (( files_added != 0 )) && files_message+=" +${files_added}"
      files_message+=" +${files_added}"
      # (( files_modified != 0 )) && files_message+=" ~${files_modified}"
      files_message+=" ~${files_modified}"
      # (( files_deleted != 0 )) && files_message+=" -${files_deleted}"
      files_message+=" -${files_deleted}"
      (( files_unmerged != 0 )) && files_message+=" !${files_unmerged}"
      files_message+="${color_off}"
  fi

  # echo "${color}${branch_symbol} ${branch} ${status_symbol}${color_off}"
  # [{HEAD-name} S +A ~B -C !D | +E ~F -G !H W]
  # printf '[%s%s%s%s%s%s%s%s%s%s%s%s]' \
  printf '%s%s%s%s%s%s' \
    "${yellow_color}[${color_off}" \
    "${cyan_color} ${branch_symbol} ${branch}${color_off}" \
    "${upstream_message}" \
    "${index_message}" \
    "${files_message}" \
    "${yellow_color} ]${color_off}"
}

function terminator::prompt::git::branch() {
  local git_dir="$1"

  [[ -z "${git_dir}" ]] && return 1

  local mode branch config step total

  # TODO verify structure here
  if [[ -d "${git_dir}/rebase-merge" ]]; then
    if [[ -f "${git_dir}/rebase-merge/interactive" ]]; then
      mode='|REBASE-i'
    else
      mode='|REBASE-m'
    fi

    branch="$(<"${git_dir}/rebase-merge/head-name")"
    step="$(<"${git_dir}/rebase-merge/msgnum")"
    total="$(<"${git_dir}/rebase-merge/end")"
  else
    if [[ -d "${git_dir}/rebase-apply" ]]; then
      step="$(<"${git_dir}/rebase-apply/next")"
      total="$(<"${git_dir}/rebase-apply/last")"

      if [[ -f "${git_dir}/rebase-apply/rebasing" ]]; then
        mode='|REBASE'
      elif [[ -f "${git_dir}/rebase-apply/applying" ]]; then
        mode='|AM'
      else
        mode='|AM/REBASE'
      fi
    elif [[ -f "${git_dir}/MERGE_HEAD" ]]; then
      mode='|MERGING'
    elif [[ -f "${git_dir}/CHERRY_PICK_HEAD" ]]; then
      mode='|CHERRY-PICKING'
    elif [[ -f "${git_dir}/REVERT_HEAD" ]]; then
      mode='|REVERTING'
    elif [[ -f "${git_dir}/BISECT_LOG" ]]; then
      mode='|BISECTING'
    fi

    branch="$(git symbolic-ref HEAD -q 2>/dev/null)"
    # {
      # dbg 'Trying describe' $sw
      # switch ($Global:GitPromptSettings.DescribeStyle) {
        # 'contains' { git describe --contains HEAD 2>$null }
        # 'branch' { git describe --contains --all HEAD 2>$null }
        # 'describe' { git describe HEAD 2>$null }
        # default { git tag --points-at HEAD 2>$null }
      # }
    # } `
    # Falling back on parsing HEAD
    if [[ -z "${branch}" ]]; then
      local ref

      if [[ -f "${git_dir}/HEAD" ]]; then
        ref="$(<"${git_dir}/HEAD")"
      else
        ref="$(git rev-parse HEAD 2>/dev/null)"
      fi

      local ref_regexp='ref: (.+)'
      if [[ "${ref}" =~ $ref_regexp ]]; then
        branch="${BASH_REMATCH[1]}"
      elif [[ -n "${ref}" ]] && (( "${#ref}" >= 7 )); then
        branch="${ref:0:7}..."
      else
        branch='unknown'
      fi
    fi
  fi

  if [[ 'true' == "$(git rev-parse --is-inside-git-dir 2>/dev/null)" ]]; then
    if [[ 'true' == "$(git rev-parse --is-bare-repository 2>/dev/null)" ]]; then
      config='BARE:'
    else
      branch='GIT_DIR!'
    fi
  fi

  if [[ -n "${step}" ]] && [[ -n "${total}" ]]; then
    mode+=" ${step}/${total}"
  fi

  echo "${config}${branch##refs/heads/}${mode}"
}
