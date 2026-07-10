#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/vpn.sh'

bats_require_minimum_version 1.5.0

################################################################################
# Helpers
################################################################################

_register_one() {
  terminator::vpn::register --name mgmt-de1 --conf-dir /tmp/wg
}

_register_two() {
  terminator::vpn::register --name mgmt-de1 --conf-dir /tmp/wg
  terminator::vpn::register --name dev-ws-laptop --conf-dir /tmp/wg
}

################################################################################
# terminator::vpn::register
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register requires --name" {
  run terminator::vpn::register --conf /tmp/x.conf

  assert_failure
  assert_output --partial '--name is required'
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register rejects a name containing a slash" {
  run terminator::vpn::register --name path/like

  assert_failure
  assert_output --partial "must not contain '/'"
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register rejects unknown options" {
  run terminator::vpn::register --name ok --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register resolves conf from conf-dir" {
  terminator::vpn::register --name mgmt-de1 --conf-dir /tmp/wg

  [[ "${TERMINATOR_VPN_NAMES[0]}" == 'mgmt-de1' ]]
  [[ "${TERMINATOR_VPN_CONFS[0]}" == '/tmp/wg/mgmt-de1.conf' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register honors explicit --conf over conf-dir" {
  terminator::vpn::register --name mgmt-de1 --conf /custom/path.conf --conf-dir /tmp/wg

  [[ "${TERMINATOR_VPN_CONFS[0]}" == '/custom/path.conf' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register honors TERMINATOR_VPN_CONF_DIR" {
  TERMINATOR_VPN_CONF_DIR='/env/wg'
  terminator::vpn::register --name mgmt-de1

  [[ "${TERMINATOR_VPN_CONFS[0]}" == '/env/wg/mgmt-de1.conf' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register does not touch the filesystem (missing conf still registers)" {
  run terminator::vpn::register --name ghost --conf /nonexistent/ghost.conf

  assert_success
  refute_output --partial 'not found'

  terminator::vpn::register --name ghost --conf /nonexistent/ghost.conf
  terminator::vpn::__is_registered__ ghost
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register first becomes default" {
  _register_one

  [[ "${TERMINATOR_VPN_CURRENT}" == 'mgmt-de1' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register second does not change default" {
  _register_two

  [[ "${TERMINATOR_VPN_CURRENT}" == 'mgmt-de1' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register --default overrides the active tunnel" {
  terminator::vpn::register --name mgmt-de1 --conf-dir /tmp/wg
  terminator::vpn::register --name dev-ws-laptop --conf-dir /tmp/wg --default

  [[ "${TERMINATOR_VPN_CURRENT}" == 'dev-ws-laptop' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::register
@test "terminator::vpn::register skips duplicates" {
  terminator::vpn::register --name mgmt-de1 --conf /first.conf
  terminator::vpn::register --name mgmt-de1 --conf /second.conf

  ((${#TERMINATOR_VPN_NAMES[@]} == 1))
  [[ "${TERMINATOR_VPN_CONFS[0]}" == '/first.conf' ]]
}

################################################################################
# terminator::vpn::use
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::use
@test "terminator::vpn::use with no args shows the active tunnel" {
  _register_one

  run terminator::vpn::use

  assert_success
  assert_output --partial 'Active: mgmt-de1'
}

# bats test_tags=terminator::vpn,terminator::vpn::use
@test "terminator::vpn::use switches the active tunnel" {
  _register_two
  terminator::vpn::use dev-ws-laptop

  [[ "${TERMINATOR_VPN_CURRENT}" == 'dev-ws-laptop' ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::use
@test "terminator::vpn::use rejects an unregistered tunnel" {
  _register_one

  run terminator::vpn::use nope

  assert_failure
  assert_output --partial 'not a registered tunnel'
}

# bats test_tags=terminator::vpn,terminator::vpn::use
@test "terminator::vpn::use -h shows usage instead of treating it as a name" {
  _register_one

  run terminator::vpn::use -h

  assert_success
  assert_output --partial 'Usage: vpn-use'
  refute_output --partial 'not a registered tunnel'
}

# bats test_tags=terminator::vpn,terminator::vpn::use
@test "terminator::vpn::use --help shows usage" {
  run terminator::vpn::use --help

  assert_success
  assert_output --partial 'Usage: vpn-use'
}

################################################################################
# terminator::vpn::list
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::list
@test "terminator::vpn::list reports none when empty" {
  run terminator::vpn::list

  assert_success
  assert_output --partial '(none)'
}

# bats test_tags=terminator::vpn,terminator::vpn::list
@test "terminator::vpn::list -h shows usage (no NAME argument)" {
  _register_one

  run terminator::vpn::list -h

  assert_success
  assert_output --partial 'Usage: vpn-list'
  refute_output --partial 'Registered tunnels:'
}

# bats test_tags=terminator::vpn,terminator::vpn::list
@test "terminator::vpn::list marks the active tunnel" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  _register_two

  run terminator::vpn::list

  assert_success
  assert_output --partial '* mgmt-de1'
  assert_output --partial 'dev-ws-laptop'
}

################################################################################
# terminator::vpn::up / down (mocked sudo + wg-quick)
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::up
@test "terminator::vpn::up runs wg-quick up with the resolved conf" {
  local dir
  dir="$(mktemp -d)"
  touch "${dir}/mgmt-de1.conf"
  terminator::vpn::register --name mgmt-de1 --conf-dir "${dir}"

  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo "sudo $*"; }

  run terminator::vpn::up mgmt-de1

  assert_success
  assert_output --partial "sudo wg-quick up ${dir}/mgmt-de1.conf"
}

# bats test_tags=terminator::vpn,terminator::vpn::up
@test "terminator::vpn::up with no arg uses the default tunnel" {
  local dir
  dir="$(mktemp -d)"
  touch "${dir}/mgmt-de1.conf"
  terminator::vpn::register --name mgmt-de1 --conf-dir "${dir}"

  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo "sudo $*"; }

  run terminator::vpn::up

  assert_success
  assert_output --partial "sudo wg-quick up ${dir}/mgmt-de1.conf"
}

# bats test_tags=terminator::vpn,terminator::vpn::up
@test "terminator::vpn::up fails when the conf is missing (checked at use time)" {
  local dir
  dir="$(mktemp -d)"
  terminator::vpn::register --name mgmt-de1 --conf-dir "${dir}"

  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo "sudo $*"; }

  run terminator::vpn::up mgmt-de1

  assert_failure
  assert_output --partial 'VPN config not found'
}

# bats test_tags=terminator::vpn,terminator::vpn::up
@test "terminator::vpn::up rejects an unregistered non-path token" {
  run terminator::vpn::up nope

  assert_failure
  assert_output --partial 'not a registered tunnel'
}

# bats test_tags=terminator::vpn,terminator::vpn::up
@test "terminator::vpn::up accepts a literal conf path (escape hatch)" {
  local dir
  dir="$(mktemp -d)"
  touch "${dir}/ad-hoc.conf"

  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo "sudo $*"; }

  run terminator::vpn::up "${dir}/ad-hoc.conf"

  assert_success
  assert_output --partial "sudo wg-quick up ${dir}/ad-hoc.conf"
}

# bats test_tags=terminator::vpn,terminator::vpn::down
@test "terminator::vpn::down runs wg-quick down with the resolved conf" {
  local dir
  dir="$(mktemp -d)"
  touch "${dir}/mgmt-de1.conf"
  terminator::vpn::register --name mgmt-de1 --conf-dir "${dir}"

  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo "sudo $*"; }

  run terminator::vpn::down mgmt-de1

  assert_success
  assert_output --partial "sudo wg-quick down ${dir}/mgmt-de1.conf"
}

################################################################################
# terminator::vpn::__real_interface__ (portable resolver)
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::real_interface
@test "__real_interface__ falls back to name when no mapping exists (Linux/down)" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"

  run terminator::vpn::__real_interface__ mgmt-de1

  assert_success
  assert_output 'mgmt-de1'
}

# bats test_tags=terminator::vpn,terminator::vpn::real_interface
@test "__real_interface__ returns the mapped interface when the socket is live (macOS up)" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  echo 'utun9' >"${TERMINATOR_VPN_RUN_DIR}/mgmt-de1.name"

  # Force the socket-liveness check true without creating a real socket.
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vpn::__is_live_socket__ { return 0; }

  run terminator::vpn::__real_interface__ mgmt-de1

  assert_success
  assert_output 'utun9'
}

# bats test_tags=terminator::vpn,terminator::vpn::real_interface
@test "__real_interface__ ignores a stale mapping with no live socket" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  echo 'utun9' >"${TERMINATOR_VPN_RUN_DIR}/mgmt-de1.name"

  # Simulate a leftover .name file after an unclean teardown (no live socket).
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vpn::__is_live_socket__ { return 1; }

  run terminator::vpn::__real_interface__ mgmt-de1

  assert_success
  assert_output 'mgmt-de1'
}

# bats test_tags=terminator::vpn,terminator::vpn::real_interface
@test "__real_interface__ reads a root-only mapping via the reader (status path)" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  echo 'utun9' >"${TERMINATOR_VPN_RUN_DIR}/mgmt-de1.name"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vpn::__is_live_socket__ { return 0; }

  local iface
  terminator::vpn::__real_interface__ mgmt-de1 iface 'cat'

  [[ "${iface}" == 'utun9' ]]
}

################################################################################
# terminator::vpn::__read_name__ (permission-safe mapping read)
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::read_name
@test "__read_name__ yields nothing for an absent file (no error)" {
  local dir
  dir="$(mktemp -d)"

  run terminator::vpn::__read_name__ "${dir}/missing.name"

  assert_success
  assert_output ''
}

# bats test_tags=terminator::vpn,terminator::vpn::read_name
@test "__read_name__ reads directly when the file is readable" {
  local dir
  dir="$(mktemp -d)"
  echo 'utun3' >"${dir}/x.name"

  run terminator::vpn::__read_name__ "${dir}/x.name"

  assert_success
  assert_output 'utun3'
}

# bats test_tags=terminator::vpn,terminator::vpn::read_name
@test "__read_name__ uses the privileged reader when given one" {
  local dir
  dir="$(mktemp -d)"
  echo 'utun4' >"${dir}/x.name"

  # A reader stands in for 'sudo cat'.
  run terminator::vpn::__read_name__ "${dir}/x.name" 'cat'

  assert_success
  assert_output 'utun4'
}

################################################################################
# terminator::vpn::status
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::status
@test "terminator::vpn::status reports a down tunnel without a misleading mapping" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  _register_one

  # No active interfaces reported -> tunnel is down.
  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo ''; }

  run terminator::vpn::status mgmt-de1

  assert_failure
  assert_output --partial "Tunnel 'mgmt-de1' is not up"
  refute_output --partial 'mgmt-de1 ->'
}

# bats test_tags=terminator::vpn,terminator::vpn::status
@test "terminator::vpn::status prints a legible name -> interface mapping when up" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  echo 'utun7' >"${TERMINATOR_VPN_RUN_DIR}/mgmt-de1.name"
  _register_one

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::vpn::__is_live_socket__ { return 0; }
  # sudo cat -> read the root-only .name mapping; sudo wg show interfaces -> active set.
  # shellcheck disable=SC2317 # invoked indirectly
  function sudo {
    case "$1" in
      cat)
        shift
        cat "$@"
        ;;
      *)
        if [[ "$*" == 'wg show interfaces' ]]; then
          echo 'utun7'
        else
          echo "sudo $*"
        fi
        ;;
    esac
  }

  run terminator::vpn::status mgmt-de1

  assert_success
  assert_output --partial 'mgmt-de1 -> utun7'
  assert_output --partial 'sudo wg show utun7'
}

# bats test_tags=terminator::vpn,terminator::vpn::status
@test "terminator::vpn::status rejects an unregistered tunnel" {
  _register_one

  run terminator::vpn::status nope

  assert_failure
  assert_output --partial 'not a registered tunnel'
}

# bats test_tags=terminator::vpn,terminator::vpn::status
@test "terminator::vpn::status with no arg shows all tunnels (no default fallback)" {
  TERMINATOR_VPN_RUN_DIR="$(mktemp -d)"
  _register_two

  # shellcheck disable=SC2317 # invoked indirectly
  function sudo { echo "sudo $*"; }

  run terminator::vpn::status

  assert_success
  assert_output --partial 'sudo wg show'
  # Must not resolve to the default tunnel (mgmt-de1) or report it down.
  refute_output --partial 'mgmt-de1 ->'
  refute_output --partial 'is not up'
}

################################################################################
# terminator::vpn::__completion__ (new convention: no precedent in other bats)
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::completion
@test "__completion__ offers all registered names" {
  _register_two

  COMP_WORDS=(vpn-up '')
  COMP_CWORD=1
  terminator::vpn::__completion__

  [[ " ${COMPREPLY[*]} " == *' mgmt-de1 '* ]]
  [[ " ${COMPREPLY[*]} " == *' dev-ws-laptop '* ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::completion
@test "__completion__ filters by prefix" {
  _register_two

  COMP_WORDS=(vpn-up dev)
  COMP_CWORD=1
  terminator::vpn::__completion__

  [[ " ${COMPREPLY[*]} " == *' dev-ws-laptop '* ]]
  [[ " ${COMPREPLY[*]} " != *' mgmt-de1 '* ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::completion
@test "__completion__ offers help flags on a dash" {
  _register_one

  COMP_WORDS=(vpn-up -)
  COMP_CWORD=1
  terminator::vpn::__completion__

  [[ " ${COMPREPLY[*]} " == *' --help '* ]]
}

# bats test_tags=terminator::vpn,terminator::vpn::completion
@test "__completion__ offers nothing past the first argument" {
  _register_one

  COMP_WORDS=(vpn-up mgmt-de1 '')
  COMP_CWORD=2
  COMPREPLY=()
  terminator::vpn::__completion__

  ((${#COMPREPLY[@]} == 0))
}

################################################################################
# Function existence sweep
################################################################################

# bats test_tags=terminator::vpn,terminator::vpn::functions
@test "terminator::vpn defines all public, internal, and lifecycle functions" {
  local fn
  for fn in \
    terminator::vpn::__index_of__ \
    terminator::vpn::__is_registered__ \
    terminator::vpn::__get_conf__ \
    terminator::vpn::__resolve_name__ \
    terminator::vpn::__is_live_socket__ \
    terminator::vpn::__read_name__ \
    terminator::vpn::__real_interface__ \
    terminator::vpn::__interface_is_up__ \
    terminator::vpn::__require_conf__ \
    terminator::vpn::__resolve_conf__ \
    terminator::vpn::__usage__ \
    terminator::vpn::__wg_quick__ \
    terminator::vpn::register \
    terminator::vpn::use \
    terminator::vpn::list \
    terminator::vpn::up \
    terminator::vpn::down \
    terminator::vpn::status \
    terminator::vpn::__completion__ \
    terminator::vpn::__enable__ \
    terminator::vpn::__disable__ \
    terminator::vpn::__export__ \
    terminator::vpn::__recall__; do
    declare -F "${fn}" >/dev/null || {
      echo "missing function: ${fn}"
      return 1
    }
  done
}
