#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

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

function terminator::gcloud::__disable__ {
  complete -r gcl

  unalias gcl
}

function terminator::gcloud::__export__ {
  export -f terminator::gcloud::alias_completion
}

function terminator::gcloud::__recall__ {
  export -fn terminator::gcloud::alias_completion
}

terminator::__module__::export
