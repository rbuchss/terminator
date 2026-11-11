#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

terminator::__module__::load || return 0

# Prints the nix profile roots in PATH-precedence order (lowest first):
# the entries of NIX_PROFILES when set, otherwise the standard multi-user
# (under /nix, e.g. Determinate) and single-user (~/.nix-profile) locations.
function terminator::nix::__profiles__ {
  local \
    profile \
    profiles

  # NIX_PROFILES is nix's own space-separated, lowest-priority-first list (set
  # by /etc/profile.d/nix.sh or the installer), so split it as-is into an array.
  read -r -a profiles <<<"${NIX_PROFILES:-/nix/var/nix/profiles/default ${HOME}/.nix-profile}"

  for profile in "${profiles[@]}"; do
    printf '%s\n' "${profile}"
  done
}

# Nix never reaches PATH in these shells: the terminator profile re-sources
# /etc/profile, whose unconditional PATH= reset drops what /etc/profile.d/nix.sh
# prepended, and its once-per-shell guard then skips re-adding it. Only PATH is
# lost; NIX_PROFILES and NIX_SSL_CERT_FILE survive, so rebuild PATH from the
# profile roots directly.
function terminator::nix::__enable__ {
  local profile

  while IFS= read -r profile; do
    if [[ -d "${profile}/bin" ]]; then
      terminator::path::prepend "${profile}/bin"
    fi
  done < <(terminator::nix::__profiles__)

  terminator::command::exists -v nix || return
}

function terminator::nix::__disable__ {
  local profile

  while IFS= read -r profile; do
    terminator::path::remove "${profile}/bin"
  done < <(terminator::nix::__profiles__)
}

function terminator::nix::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::nix::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
