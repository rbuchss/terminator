#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/styles.sh"
source "${BASH_SOURCE[0]%/*/*}/file.sh"

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

  local inside_work_tree="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  local bare_repo="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  local inside_git_dir="${repo_info##*$'\n'}"
  local git_dir="${repo_info%$'\n'*}"

  # echo "inside_work_tree: ${inside_work_tree}"
  # echo "bare_repo: ${bare_repo}"
  # echo "inside_git_dir: ${inside_git_dir}"
  # echo "git_dir: ${git_dir}"

  local response=()

  if [[ 'true' == "${inside_git_dir}" ]] && [[ 'true' != "${bare_repo}" ]]; then
    response+=('GIT_DIR!')
  elif [[ 'true' == "${inside_work_tree}" ]]; then
    while IFS= read -r result; do
      response+=("${result}")
    done < <(terminator::prompt::git::status "${git_dir}")
  fi

  if [[ 'true' == "${bare_repo}" ]]; then
    response[0]="BARE:${response[0]}"
  fi

  terminator::prompt::git::format "${response[@]}"
}

function terminator::prompt::git::status() {
  local git_dir="$1"

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
  # local stash_count=0

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

  [[ -z "${branch}" ]] && branch="$(terminator::prompt::git::branch "${git_dir}")"

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
  # local stash_count="${14}"

  local branch_symbol
  if [[ "${branch:0:1}" != '(' ]]; then
    branch_symbol="$(terminator::styles::branch_symbol)"
  else
    branch_symbol="$(terminator::styles::detached_head_symbol)"
  fi

  local branch_color
  local upstream_same_color upstream_ahead_color upstream_behind_color upstream_gone_color
  local index_color files_color
  local divider_color enclosure_color
  local color_off
  terminator::styles::branch_color branch_color
  terminator::styles::upstream_same_color upstream_same_color
  terminator::styles::upstream_ahead_color upstream_ahead_color
  terminator::styles::upstream_behind_color upstream_behind_color
  terminator::styles::upstream_gone_color upstream_gone_color
  terminator::styles::index_color index_color
  terminator::styles::files_color files_color
  terminator::styles::divider_color divider_color
  terminator::styles::enclosure_color enclosure_color
  terminator::color::off color_off

  local branch_message="${branch_color}${branch_symbol} ${branch}${color_off}"

  local upstream_message
  if [[ -n "${upstream}" ]]; then
    if [[ -n "${gone}" ]]; then
      upstream_message+=" ${upstream_gone_color}x${color_off}"
    elif (( ahead_by == 0 && behind_by == 0 )); then
      upstream_message+=" ${upstream_same_color}≡${color_off}"
    # elif (( ahead_by != 0 && behind_by != 0 )); then # TODO add flag to enable
    #   upstream_message+=" ${upstream_ahead_color}${ahead_by}${color_off}"
    #   upstream_message+="${upstream_same_color}↕${color_off}"
    #   upstream_message+="${upstream_behind_color}${behind_by}${color_off}"
    else
      (( ahead_by != 0 )) && upstream_message+=" ${upstream_ahead_color}↑${ahead_by}${color_off}"
      (( behind_by != 0 )) && upstream_message+=" ${upstream_behind_color}↓${behind_by}${color_off}"
    fi
  fi

  local index_message
  if (( index_added != 0 )) \
    || (( index_modified != 0 )) \
    || (( index_deleted != 0 )) \
    || (( index_unmerged != 0 )); then
      index_message+="${index_color}"
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
          files_message+=" ${divider_color}|${color_off}"
      fi
      files_message+="${files_color}"
      # (( files_added != 0 )) && files_message+=" +${files_added}"
      files_message+=" +${files_added}"
      # (( files_modified != 0 )) && files_message+=" ~${files_modified}"
      files_message+=" ~${files_modified}"
      # (( files_deleted != 0 )) && files_message+=" -${files_deleted}"
      files_message+=" -${files_deleted}"
      (( files_unmerged != 0 )) && files_message+=" !${files_unmerged}"
      files_message+="${color_off}"
  fi

  # [{HEAD-name} S +A ~B -C !D | +E ~F -G !H W]
  printf '%s%s%s%s%s%s' \
    "${enclosure_color}[ ${color_off}" \
    "${branch_message}" \
    "${upstream_message}" \
    "${index_message}" \
    "${files_message}" \
    "${enclosure_color} ]${color_off}"
}

function terminator::prompt::git::branch() {
  local git_dir="$1"

  [[ -z "${git_dir}" ]] && return 1

  local mode branch step total todo

  if [[ -d "${git_dir}/rebase-merge" ]]; then
    mode='|REBASE'

    terminator::file::read_first_line \
      "${git_dir}/rebase-merge/head-name" branch
    terminator::file::read_first_line \
      "${git_dir}/rebase-merge/msgnum" step
    terminator::file::read_first_line \
      "${git_dir}/rebase-merge/end" total
  else
    if [[ -d "${git_dir}/rebase-apply" ]]; then
      terminator::file::read_first_line \
        "${git_dir}/rebase-apply/next" step
      terminator::file::read_first_line \
        "${git_dir}/rebase-apply/last" total

      if [[ -f "${git_dir}/rebase-apply/rebasing" ]]; then
        terminator::file::read_first_line \
          "${git_dir}/rebase-apply/head-name" branch
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
    elif terminator::file::read_first_line \
      "${git_dir}/sequencer/todo" todo; then
          case "${todo}" in
            p[\ $'\t']|pick[\ $'\t']*) mode="|CHERRY-PICKING" ;;
            revert[\ $'\t']*) mode="|REVERTING" ;;
          esac
    elif [[ -f "${git_dir}/BISECT_LOG" ]]; then
      mode='|BISECTING'
    fi

    if [[ -n "${branch}" ]]; then
      :
    elif [[ -h "${git_dir}/HEAD" ]]; then
      # symlink symbolic ref
      branch="$(git symbolic-ref HEAD -q 2>/dev/null)"
    else
      # Falling back on parsing HEAD
      local ref

      if [[ -f "${git_dir}/HEAD" ]]; then
        terminator::file::read_first_line \
          "${git_dir}/HEAD" ref
      else
        ref="$(git rev-parse HEAD 2>/dev/null)"
      fi

      local ref_regexp='ref: (.+)'
      if [[ "${ref}" =~ $ref_regexp ]]; then
        branch="${BASH_REMATCH[1]}"
      elif [[ -n "${ref}" ]] && (( "${#ref}" >= 7 )); then
        branch="(${ref:0:7}...)"
      else
        branch='unknown'
      fi
    fi
  fi

  if [[ -n "${step}" ]] && [[ -n "${total}" ]]; then
    mode+=" ${step}/${total}"
  fi

  echo "${branch##refs/heads/}${mode}"
}
