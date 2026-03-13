#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

terminator::__module__::load || return 0

function terminator::gcloud::__enable__ {
  terminator::command::exists -v gcloud || return

  local google_sdk_root_path

  google_sdk_root_path="$(gcloud info --format='value(installation.sdk_root)')"

  source "${google_sdk_root_path}/completion.bash.inc"

  alias gcl='gcloud'

  # Note gcloud uses this to define its completion. See:
  #
  #   $ complete -p gcloud
  #   complete -o nospace -F _python_argcomplete gcloud
  #
  complete -o nospace -F terminator::gcloud::alias_completion gcl
}

# This wrapper function is needed since the gcloud cli invokes itself to perform
# completion. If the first arg is not gcloud this will fail. In the case of our
# alias this will be the first arg. To fix this we pop the first arg off and
# replace it with gcloud.
function terminator::gcloud::alias_completion {
  shift # pops off the first arg here since this will be our alias
  # then use gcloud as the first arg and passes all other args on for completion
  _python_argcomplete gcloud "$@"
}

# Ensures gcloud is authenticated. Re-authenticates if tokens are expired.
function terminator::gcloud::auth {
  local __gcloud_auth_account__

  __gcloud_auth_account__="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"

  if [[ -z "${__gcloud_auth_account__}" ]]; then
    echo "No active gcloud authentication found. Logging in..."
    gcloud auth login || return 1
  elif ! gcloud auth print-access-token >/dev/null 2>&1; then
    echo "Gcloud tokens expired for: ${__gcloud_auth_account__}. Re-authenticating..."
    gcloud auth login || return 1
  else
    echo "Authenticated with gcloud as: ${__gcloud_auth_account__}"
  fi
}

function terminator::gcloud::__disable__ {
  complete -r gcl

  unalias gcl
}

function terminator::gcloud::__export__ {
  export -f terminator::gcloud::alias_completion
  export -f terminator::gcloud::auth
}

# KCOV_EXCL_START
function terminator::gcloud::__recall__ {
  export -fn terminator::gcloud::alias_completion
  export -fn terminator::gcloud::auth
}
# KCOV_EXCL_STOP

terminator::__module__::export
