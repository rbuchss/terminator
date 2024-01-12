#!/bin/bash

__setup_with_coverage__() {
  cat <<HERE
    setup() {
      if [[ -n "\${KCOV_BASH_XTRACEFD+x}" ]]; then
        set -o functrace
        trap 'echo "kcov@\${BASH_SOURCE}@\${LINENO}@" >&\$KCOV_BASH_XTRACEFD' DEBUG
      fi
      source "$1/$2"
    }

    teardown() {
      if [[ -n "\${KCOV_BASH_XTRACEFD+x}" ]]; then
        set +o functrace
        trap - DEBUG
      fi
    }
HERE
}

setup_with_coverage() {
  eval "$(__setup_with_coverage__ "$(repo_root)" "$1")"
}
