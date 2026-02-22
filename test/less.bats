#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/less.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::less::__enable__
################################################################################

# bats test_tags=terminator::less,terminator::less::__enable__
@test "terminator::less::__enable__ sets-LESS_TERMCAP-variables" {
  # Clear any existing values
  unset LESS_TERMCAP_mb LESS_TERMCAP_md LESS_TERMCAP_me
  unset LESS_TERMCAP_se LESS_TERMCAP_so LESS_TERMCAP_ue LESS_TERMCAP_us

  terminator::less::__enable__

  [[ -n "${LESS_TERMCAP_mb}" ]]
  [[ -n "${LESS_TERMCAP_md}" ]]
  [[ -n "${LESS_TERMCAP_me}" ]]
  [[ -n "${LESS_TERMCAP_se}" ]]
  [[ -n "${LESS_TERMCAP_so}" ]]
  [[ -n "${LESS_TERMCAP_ue}" ]]
  [[ -n "${LESS_TERMCAP_us}" ]]
}

################################################################################
# terminator::less::__disable__
################################################################################

# bats test_tags=terminator::less,terminator::less::__disable__
@test "terminator::less::__disable__ unsets-LESS_TERMCAP-variables" {
  # Set some values
  LESS_TERMCAP_mb='test'
  LESS_TERMCAP_md='test'
  LESS_TERMCAP_me='test'
  LESS_TERMCAP_se='test'
  LESS_TERMCAP_so='test'
  LESS_TERMCAP_ue='test'
  LESS_TERMCAP_us='test'

  terminator::less::__disable__

  [[ -z "${LESS_TERMCAP_mb+x}" ]]
  [[ -z "${LESS_TERMCAP_md+x}" ]]
  [[ -z "${LESS_TERMCAP_me+x}" ]]
  [[ -z "${LESS_TERMCAP_se+x}" ]]
  [[ -z "${LESS_TERMCAP_so+x}" ]]
  [[ -z "${LESS_TERMCAP_ue+x}" ]]
  [[ -z "${LESS_TERMCAP_us+x}" ]]
}
