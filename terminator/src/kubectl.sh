#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/src/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/src/logger.sh"

function terminator::kubectl::__enable__ {
  terminator::command::exists -v kubectl || return

  eval "$(kubectl completion bash)"

  alias k=kubectl
  complete -o default -F __start_kubectl k

  alias kubectl-add='terminator::kubectl::cluster::add'
  alias kubectl-remove='terminator::kubectl::cluster::remove'
}

function terminator::kubectl::__disable__ {
  unalias kubectl-add
  unalias kubectl-remove
}

function terminator::kubectl::cluster::add::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS]

  -p, --provider     Provider to use.
                     Choices: [aws azure gcloud hosted]

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::kubectl::cluster::add {
  local \
    provider \
    provider_command \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 terminator::kubectl::cluster::add::usage
        return 0
        ;;
      -p | --provider)
        shift
        provider="$1"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  case "${provider}" in
    aws)
      provider_command='terminator::kubectl::cluster::add::aws'
      ;;
    azure)
      provider_command='terminator::kubectl::cluster::add::azure'
      ;;
    gcloud)
      provider_command='terminator::kubectl::cluster::add::gcloud'
      ;;
    hosted)
      provider_command='terminator::kubectl::cluster::add::hoster'
      ;;
    *)
      >&2 echo "ERROR: ${FUNCNAME[0]} invalid provider option: '${provider}'"
      >&2 terminator::kubectl::cluster::add::usage
      return 1
      ;;
  esac

  terminator::logger::info "Add kubectl config for provider: '${provider}'"
  terminator::kubectl::config::backup

  "${provider_command}" "${arguments[@]}"
}

function terminator::kubectl::cluster::add::aws {
  >&2 echo 'ERROR - aws not implemented'
  return 1
}

function terminator::kubectl::cluster::add::azure {
  >&2 echo 'ERROR - azure not implemented'
  return 1
}

function terminator::kubectl::cluster::add::gcloud {
  local \
    project \
    cluster \
    region

  while (( $# != 0 )); do
    case "$1" in
      --project)
        shift
        project="$1"
        ;;
      --cluster)
        shift
        cluster="$1"
        ;;
      --region)
        shift
        region="$1"
        ;;
    esac
    shift
  done

  if [[ -z "${project}" ]] || [[ -z "${cluster}" ]] || [[ -z "${region}" ]]; then
    if ! terminator::command::exists fzf; then
      terminator::logger::error 'Requires fzf which was not found - Exiting'
      return 1
    fi
  fi

  if [[ -z "${project}" ]]; then
    local projects=()

    while IFS= read -r result; do
      projects+=("${result}")
    done < <(
      gcloud projects list \
        --format='value(projectId)' \
        --sort-by=~projectId
      )

    if (( ${#projects[@]} == 0 )); then
      >&2 echo 'ERROR: No gcloud projects found - Exiting'
      return 1
    fi

    project="$(
      printf '%s\n' "${projects[@]}" \
        | fzf \
          --header='Select gcloud project to use' \
          --preview 'gcloud projects describe {1}' \
          --preview-window=up:40%
      )"

    if [[ -z "${project}" ]]; then
      >&2 echo 'ERROR: No gcloud project selected - Exiting'
      return 1
    fi
  fi

  if [[ -z "${cluster}" ]] || [[ -z "${region}" ]]; then
    local clusters=()

    while IFS= read -r result; do
      clusters+=("${result}")
    done < <(
      gcloud container clusters list \
        --format='value(name, location)' \
        --sort-by=~name,~location \
        --project "${project}"
      )

    if (( ${#clusters[@]} == 0 )); then
      >&2 echo 'ERROR: No gcloud clusters found - Exiting'
      return 1
    fi

    read -r cluster region < <(
      printf '%s\n' "${clusters[@]}" \
        | fzf \
          --header='Select gcloud container cluster and region to use' \
          --preview "gcloud container clusters describe {1} --region {2} --project ${project}" \
          --preview-window=up:80%
      )

    if [[ -z "${cluster}" ]] || [[ -z "${region}" ]]; then
      >&2 echo 'ERROR: No gcloud container cluster or region selected - Exiting'
      return 1
    fi
  fi

  terminator::logger::info \
    "Adding kubectl config for gcloud project: '${project}' cluster: '${cluster}' region: '${region}'"

  gcloud container clusters get-credentials \
    "${cluster}" \
    --project "${project}" \
    --region "${region}"
}

function terminator::kubectl::cluster::add::hosted {
  >&2 echo 'ERROR - hosted not implemented'
  return 1
}

function terminator::kubectl::cluster::remove::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS]

  -c, --cluster      Clusters to remove

  -h, --help         Display this help message
USAGE_TEXT
}

function terminator::kubectl::cluster::remove {
  local \
    clusters=() \
    linked_contexts=() \
    linked_users=() \
    cluster \
    context \
    user

  while (( $# != 0 )); do
    case "$1" in
      -c | --cluster)
        shift
        clusters+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#clusters[@]} == 0 )); then
    if ! terminator::command::exists fzf; then
      terminator::logger::error 'Requires fzf which was not found - Exiting'
      return 1
    fi

    if ! terminator::command::exists jq; then
      terminator::logger::error 'Requires jq which was not found - Exiting'
      return 1
    fi
  fi

  if (( ${#clusters[@]} == 0 )); then
    local _clusters=()

    while IFS= read -r result; do
      _clusters+=("${result}")
    done < <(
      kubectl config view \
        -o jsonpath='{range .clusters[*]}{.name}{"\n"}{end}'
      )

    if (( ${#_clusters[@]} == 0 )); then
      >&2 echo 'ERROR: No clusters found - Exiting'
      return 1
    fi

    local preview_command

    printf -v preview_command \
      '%s && %s' \
      "kubectl config view -o jsonpath=\"{.clusters[?(@.name=={1})]}\" | jq" \
      "kubectl config view -o jsonpath=\"{.contexts[?(@.context.cluster=={1})]}\" | jq"

    while IFS= read -r result; do
      clusters+=("${result}")
    done < <(
      printf '%s\n' "${_clusters[@]}" \
        | fzf \
          --multi \
          --header='Select clusters to remove' \
          --preview "${preview_command}" \
          --preview-window=up:80%
      )

    if (( ${#clusters[@]} == 0 )); then
      >&2 echo 'ERROR: No clusters selected - Exiting'
      return 1
    fi
  fi

  terminator::logger::info "Removing kubectl config for clusters: [${clusters[*]}]"
  terminator::kubectl::config::backup

  for cluster in "${clusters[@]}"; do
    while IFS= read -r result; do
      read -r context user <<< "${result}"
      linked_contexts+=("${cluster}:${context}")
      linked_users+=("${cluster}:${user}")
    done < <(
      kubectl config view \
        -o jsonpath="{range .contexts[?(@.context.cluster=='${cluster}')]}{.name}{'\t'}{.context.user}{'\n'}{end}"
      )
  done

  terminator::logger::info 'Removing cluster contexts'

  for linked_context in "${linked_contexts[@]}"; do
    IFS=':' read -r cluster context <<< "${linked_context}"

    terminator::logger::info "Removing context: '${context}' for cluster: '${cluster}'"

    kubectl config delete-context "${context}"
  done

  terminator::logger::info 'Removing clusters'

  for cluster in "${clusters[@]}"; do
    terminator::logger::info "Removing cluster: '${cluster}'"

    kubectl config delete-cluster "${cluster}"
  done

  terminator::logger::info 'Removing dangling users'

  local \
    remaining_contexts=() \
    user_to_remove \
    user_in_use \
    contexts_using_user

  # Get all remaining contexts with their users after cluster removal
  while IFS= read -r result; do
    remaining_contexts+=("${result}")
  done < <(
    kubectl config view \
      -o jsonpath='{range .contexts[*]}{.name}{"\t"}{.context.user}{"\n"}{end}'
    )

  # Check each linked user to see if it's still referenced
  for linked_user in "${linked_users[@]}"; do
    IFS=':' read -r cluster user_to_remove <<< "${linked_user}"
    user_in_use=0
    contexts_using_user=()

    # Check if this user is still referenced in any remaining context
    for remaining_context in "${remaining_contexts[@]}"; do
      read -r context_name context_user <<< "${remaining_context}"

      if [[ "${user_to_remove}" == "${context_user}" ]]; then
        user_in_use=1
        contexts_using_user+=("${context_name}")
      fi
    done

    if (( user_in_use == 1 )); then
      terminator::logger::warning \
        "User: '${user_to_remove}' still referenced in contexts: [${contexts_using_user[*]}] - not removing"
    else
      terminator::logger::info "Removing dangling user: '${user_to_remove}'"

      kubectl config delete-user "${user_to_remove}"
    fi
  done
}

function terminator::kubectl::config::backup {
  local \
    timestamp \
    kube_dir="${HOME}/.kube" \
    backup_dir \
    backup_file

  timestamp="$(date '+%Y-%m-%dT%H-%M-%S')"
  config_file="${kube_dir}/config"
  backup_dir="${kube_dir}/backups"
  backup_file="${backup_dir}/${timestamp}-config"

  if [[ ! -f "${config_file}" ]]; then
    terminator::logger::error "No kubectl config file found at ${config_file}"
    return 1
  fi

  mkdir -p "${backup_dir}"

  if ! cp "${config_file}" "${backup_file}"; then
    terminator::logger::error "Failed to backup kubectl config"
    return 1
  fi

  terminator::logger::info "Backed up kubectl config to: ${backup_file}"
}

function terminator::kubectl::__export__ {
  export -f terminator::kubectl::cluster::add
  export -f terminator::kubectl::cluster::add::usage
  export -f terminator::kubectl::cluster::add::aws
  export -f terminator::kubectl::cluster::add::azure
  export -f terminator::kubectl::cluster::add::gcloud
  export -f terminator::kubectl::cluster::add::hosted
  export -f terminator::kubectl::cluster::remove
  export -f terminator::kubectl::cluster::remove::usage
  export -f terminator::kubectl::config::backup
}

function terminator::kubectl::__recall__ {
  export -fn terminator::kubectl::cluster::add
  export -fn terminator::kubectl::cluster::add::usage
  export -fn terminator::kubectl::cluster::add::aws
  export -fn terminator::kubectl::cluster::add::azure
  export -fn terminator::kubectl::cluster::add::gcloud
  export -fn terminator::kubectl::cluster::add::hosted
  export -fn terminator::kubectl::cluster::remove
  export -fn terminator::kubectl::cluster::remove::usage
  export -fn terminator::kubectl::config::backup
}

terminator::__module__::export
