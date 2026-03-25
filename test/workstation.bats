#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/workstation.sh'

bats_require_minimum_version 1.5.0

################################################################################
# Helper: register a test workstation with GCP provider
################################################################################

_register_test_ws() {
  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --zone us-east1-c \
    --project test-project
}

_register_two_ws() {
  _register_test_ws
  terminator::workstation::register \
    --name dev-ws \
    --provider gcp \
    --zone us-central1-a \
    --project dev-project
}

################################################################################
# terminator::workstation::register
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register requires --name" {
  run terminator::workstation::register --provider gcp

  assert_failure
  assert_output --partial 'ERROR: --name is required'
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register requires --provider" {
  run terminator::workstation::register --name test-ws

  assert_failure
  assert_output --partial 'ERROR: --provider is required'
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register adds to registry" {
  _register_test_ws

  [[ "${TERMINATOR_WORKSTATION_NAMES[0]}" == "test-ws" ]]
  [[ "${TERMINATOR_WORKSTATION_PROVIDERS[0]}" == "gcp" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register first becomes default" {
  _register_test_ws

  [[ "${TERMINATOR_WORKSTATION_CURRENT}" == "test-ws" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register second does not change default" {
  _register_two_ws

  [[ "${TERMINATOR_WORKSTATION_CURRENT}" == "test-ws" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register skips duplicate" {
  _register_test_ws
  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --zone us-west1-b \
    --project other-project

  ((${#TERMINATOR_WORKSTATION_NAMES[@]} == 1))
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register stores auth hook" {
  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --auth-hook my_auth_func \
    --zone us-east1-c \
    --project test-project

  [[ "${TERMINATOR_WORKSTATION_AUTH_HOOKS[0]}" == "my_auth_func" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register uses provider default auth hook when not specified" {
  _register_test_ws

  [[ "${TERMINATOR_WORKSTATION_AUTH_HOOKS[0]}" == "terminator::workstation::provider::gcp::auth" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register explicit --auth-hook overrides provider default" {
  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --auth-hook my_custom_auth \
    --zone us-east1-c \
    --project test-project

  [[ "${TERMINATOR_WORKSTATION_AUTH_HOOKS[0]}" == "my_custom_auth" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register no auth hook when provider has no default" {
  terminator::workstation::register \
    --name test-ws \
    --provider fake_provider

  [[ "${TERMINATOR_WORKSTATION_AUTH_HOOKS[0]}" == "" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register --default overrides active workstation" {
  _register_test_ws

  terminator::workstation::register \
    --name dev-ws \
    --provider gcp \
    --default \
    --zone us-central1-a \
    --project dev-project

  [[ "${TERMINATOR_WORKSTATION_CURRENT}" == "dev-ws" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register without --default keeps existing active" {
  _register_two_ws

  [[ "${TERMINATOR_WORKSTATION_CURRENT}" == "test-ws" ]]
}

################################################################################
# terminator::workstation::__index_of__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__index_of__
@test "terminator::workstation::__index_of__ finds registered name" {
  _register_two_ws

  run terminator::workstation::__index_of__ "dev-ws"

  assert_success
  assert_output "1"
}

# bats test_tags=terminator::workstation,terminator::workstation::__index_of__
@test "terminator::workstation::__index_of__ returns 1 for missing name" {
  _register_test_ws

  run terminator::workstation::__index_of__ "nonexistent"

  assert_failure
}

# bats test_tags=terminator::workstation,terminator::workstation::__index_of__
@test "terminator::workstation::__index_of__ writes to output var" {
  _register_two_ws

  local result
  terminator::workstation::__index_of__ "dev-ws" result

  [[ "${result}" == "1" ]]
}

################################################################################
# terminator::workstation::__is_registered__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__is_registered__
@test "terminator::workstation::__is_registered__ returns 0 for registered" {
  _register_test_ws

  run terminator::workstation::__is_registered__ "test-ws"

  assert_success
}

# bats test_tags=terminator::workstation,terminator::workstation::__is_registered__
@test "terminator::workstation::__is_registered__ returns 1 for unregistered" {
  run terminator::workstation::__is_registered__ "nonexistent"

  assert_failure
}

################################################################################
# terminator::workstation::__get_provider__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__get_provider__
@test "terminator::workstation::__get_provider__ returns provider" {
  _register_test_ws

  run terminator::workstation::__get_provider__ "test-ws"

  assert_success
  assert_output "gcp"
}

# bats test_tags=terminator::workstation,terminator::workstation::__get_provider__
@test "terminator::workstation::__get_provider__ writes to output var" {
  _register_test_ws

  local result
  terminator::workstation::__get_provider__ "test-ws" result

  [[ "${result}" == "gcp" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::__get_provider__
@test "terminator::workstation::__get_provider__ fails for unregistered" {
  run terminator::workstation::__get_provider__ "nonexistent"

  assert_failure
}

################################################################################
# terminator::workstation::__get_auth_hook__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__get_auth_hook__
@test "terminator::workstation::__get_auth_hook__ returns hook" {
  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --auth-hook my_auth \
    --zone us-east1-c \
    --project test-project

  run terminator::workstation::__get_auth_hook__ "test-ws"

  assert_success
  assert_output "my_auth"
}

# bats test_tags=terminator::workstation,terminator::workstation::__get_auth_hook__
@test "terminator::workstation::__get_auth_hook__ returns empty when provider has no default" {
  terminator::workstation::register \
    --name test-ws \
    --provider fake_provider

  local result
  terminator::workstation::__get_auth_hook__ "test-ws" result

  [[ "${result}" == "" ]]
}

################################################################################
# terminator::workstation::__extract_instance__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__extract_instance__
@test "terminator::workstation::__extract_instance__ finds instance in path" {
  _register_test_ws

  local result
  terminator::workstation::__extract_instance__ result "test-ws:~/file"

  [[ "${result}" == "test-ws" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::__extract_instance__
@test "terminator::workstation::__extract_instance__ fails with no match" {
  _register_test_ws

  run terminator::workstation::__extract_instance__ result "unknown:~/file"

  assert_failure
}

# bats test_tags=terminator::workstation,terminator::workstation::__extract_instance__
@test "terminator::workstation::__extract_instance__ finds in mixed args" {
  _register_test_ws

  local result
  terminator::workstation::__extract_instance__ result "--recurse" "./local" "test-ws:~/remote"

  [[ "${result}" == "test-ws" ]]
}

################################################################################
# terminator::workstation::__parse_instance__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__parse_instance__
@test "terminator::workstation::__parse_instance__ parses -w flag" {
  _register_test_ws

  local inst
  terminator::workstation::__parse_instance__ inst -w test-ws ls -la

  [[ "${inst}" == "test-ws" ]]
  [[ "${__TERMINATOR_WS_PASSTHROUGH__[0]}" == "ls" ]]
  [[ "${__TERMINATOR_WS_PASSTHROUGH__[1]}" == "-la" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::__parse_instance__
@test "terminator::workstation::__parse_instance__ defaults to TERMINATOR_WORKSTATION_CURRENT" {
  _register_test_ws

  local inst
  terminator::workstation::__parse_instance__ inst ls -la

  [[ "${inst}" == "test-ws" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::__parse_instance__
@test "terminator::workstation::__parse_instance__ returns 2 for --help" {
  run terminator::workstation::__parse_instance__ inst --help

  assert_failure 2
}

# bats test_tags=terminator::workstation,terminator::workstation::__parse_instance__
@test "terminator::workstation::__parse_instance__ returns 0 normally" {
  _register_test_ws

  local inst

  terminator::workstation::__parse_instance__ inst ls
  local rc=$?

  ((rc == 0))
}

################################################################################
# terminator::workstation::__run_auth_hook__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::__run_auth_hook__
@test "terminator::workstation::__run_auth_hook__ skips when no hook set" {
  terminator::workstation::register \
    --name test-ws \
    --provider fake_provider

  run terminator::workstation::__run_auth_hook__ "test-ws"

  assert_success
}

# bats test_tags=terminator::workstation,terminator::workstation::__run_auth_hook__
@test "terminator::workstation::__run_auth_hook__ calls hook function" {
  function test_auth_hook { echo "authed"; }

  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --auth-hook test_auth_hook \
    --zone us-east1-c \
    --project test-project

  run terminator::workstation::__run_auth_hook__ "test-ws"

  assert_success
  assert_output "authed"
}

# bats test_tags=terminator::workstation,terminator::workstation::__run_auth_hook__
@test "terminator::workstation::__run_auth_hook__ fails when hook missing" {
  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --auth-hook nonexistent_func \
    --zone us-east1-c \
    --project test-project

  run terminator::workstation::__run_auth_hook__ "test-ws"

  assert_failure
  assert_output --partial "auth hook 'nonexistent_func' not found"
}

################################################################################
# terminator::workstation::use
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::use
@test "terminator::workstation::use shows current when no args" {
  _register_test_ws

  run terminator::workstation::use

  assert_success
  assert_output "Active: test-ws"
}

# bats test_tags=terminator::workstation,terminator::workstation::use
@test "terminator::workstation::use shows none when no default" {
  run terminator::workstation::use

  assert_success
  assert_output "Active: none"
}

# bats test_tags=terminator::workstation,terminator::workstation::use
@test "terminator::workstation::use switches workstation" {
  _register_two_ws

  terminator::workstation::use "dev-ws"

  [[ "${TERMINATOR_WORKSTATION_CURRENT}" == "dev-ws" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::use
@test "terminator::workstation::use fails for unregistered" {
  _register_test_ws

  run terminator::workstation::use "nonexistent"

  assert_failure
  assert_output --partial "ERROR: 'nonexistent' is not a registered workstation"
}

################################################################################
# terminator::workstation::list
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::list
@test "terminator::workstation::list shows registered with active marker" {
  _register_two_ws

  run terminator::workstation::list

  assert_success
  assert_output --partial "* test-ws"
  assert_output --partial "  dev-ws"
}

# bats test_tags=terminator::workstation,terminator::workstation::list
@test "terminator::workstation::list shows GCP details" {
  _register_test_ws

  run terminator::workstation::list

  assert_success
  assert_output --partial "zone: us-east1-c, project: test-project"
}

################################################################################
# GCP provider: configure
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::configure
@test "provider::gcp::configure stores zone and project at correct index" {
  _register_two_ws

  [[ "${TERMINATOR_WORKSTATION_GCP_ZONES[0]}" == "us-east1-c" ]]
  [[ "${TERMINATOR_WORKSTATION_GCP_PROJECTS[0]}" == "test-project" ]]
  [[ "${TERMINATOR_WORKSTATION_GCP_ZONES[1]}" == "us-central1-a" ]]
  [[ "${TERMINATOR_WORKSTATION_GCP_PROJECTS[1]}" == "dev-project" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::configure
@test "provider::gcp::configure requires --name" {
  run terminator::workstation::provider::gcp::configure --zone us-east1-c

  assert_failure
  assert_output --partial '--name is required'
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::configure
@test "provider::gcp::configure fails for unregistered name" {
  run terminator::workstation::provider::gcp::configure --name nonexistent --zone us-east1-c

  assert_failure
  assert_output --partial "'nonexistent' is not registered"
}

################################################################################
# GCP provider: format_info
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::format_info
@test "provider::gcp::format_info outputs zone and project" {
  _register_test_ws

  run terminator::workstation::provider::gcp::format_info "test-ws"

  assert_success
  assert_output "zone: us-east1-c, project: test-project"
}

################################################################################
# GCP provider: ssh (mocked gcloud)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::ssh
@test "provider::gcp::ssh calls gcloud with correct args" {
  _register_test_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::provider::gcp::ssh "test-ws" -A

  assert_success
  assert_output "gcloud compute ssh --zone us-east1-c test-ws --project test-project -- -A"
}

################################################################################
# GCP provider: scp (mocked gcloud)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::scp
@test "provider::gcp::scp calls gcloud with correct args" {
  _register_test_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::provider::gcp::scp "test-ws" "test-ws:~/file" "./local"

  assert_success
  assert_output "gcloud compute scp --zone us-east1-c --project test-project test-ws:~/file ./local"
}

################################################################################
# GCP provider: rsync_export_env
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::rsync_export_env
@test "provider::gcp::rsync_export_env exports env vars" {
  _register_test_ws

  terminator::workstation::provider::gcp::rsync_export_env "test-ws"

  [[ "${__TERMINATOR_RSYNC_GCP_ZONE__}" == "us-east1-c" ]]
  [[ "${__TERMINATOR_RSYNC_GCP_INSTANCE__}" == "test-ws" ]]
  [[ "${__TERMINATOR_RSYNC_GCP_PROJECT__}" == "test-project" ]]
}

################################################################################
# Dispatch: ssh (mocked provider + auth)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh dispatches to provider" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::gcloud::auth { :; }
  _register_test_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::ssh ls -la

  assert_success
  assert_output --partial "gcloud compute ssh --zone us-east1-c test-ws --project test-project -- ls -la"
}

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh with -w flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::gcloud::auth { :; }
  _register_two_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::ssh -w dev-ws ls

  assert_success
  assert_output --partial "gcloud compute ssh --zone us-central1-a dev-ws --project dev-project -- ls"
}

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh --help shows usage" {
  _register_test_ws

  run terminator::workstation::ssh --help

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "--workstation"
}

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh fails with no workstation and no default" {
  TERMINATOR_WORKSTATION_CURRENT=""

  run terminator::workstation::ssh

  assert_failure
  assert_output --partial "ERROR: no workstation specified and no default set"
}

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh fails for unregistered workstation" {
  _register_test_ws

  run terminator::workstation::ssh -w nonexistent

  assert_failure
  assert_output --partial "ERROR: 'nonexistent' is not a registered workstation"
}

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh runs auth hook before dispatch" {
  function my_auth { echo "auth-called"; }

  terminator::workstation::register \
    --name test-ws \
    --provider gcp \
    --auth-hook my_auth \
    --zone us-east1-c \
    --project test-project

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::ssh

  assert_success
  assert_output --partial "auth-called"
  assert_output --partial "gcloud compute ssh"
}

################################################################################
# Dispatch: scp (mocked provider)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::scp
@test "terminator::workstation::scp dispatches to provider" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::gcloud::auth { :; }
  _register_test_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::scp "test-ws:~/remote" "./local"

  assert_success
  assert_output --partial "gcloud compute scp --zone us-east1-c --project test-project test-ws:~/remote ./local"
}

# bats test_tags=terminator::workstation,terminator::workstation::scp
@test "terminator::workstation::scp --help shows usage" {
  _register_test_ws

  run terminator::workstation::scp --help

  assert_success
  assert_output --partial "Usage:"
}

# bats test_tags=terminator::workstation,terminator::workstation::scp
@test "terminator::workstation::scp with no args shows usage and fails" {
  _register_test_ws

  run terminator::workstation::scp

  assert_failure
  assert_output --partial "Usage:"
}

# bats test_tags=terminator::workstation,terminator::workstation::scp
@test "terminator::workstation::scp with -w flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::gcloud::auth { :; }
  _register_two_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::scp -w dev-ws "dev-ws:~/remote" "./local"

  assert_success
  assert_output --partial "gcloud compute scp --zone us-central1-a --project dev-project"
}

################################################################################
# Dispatch: rsync (mocked)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::rsync
@test "terminator::workstation::rsync --help shows usage" {
  _register_test_ws

  run terminator::workstation::rsync --help

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "Excludes:"
}

# bats test_tags=terminator::workstation,terminator::workstation::rsync
@test "terminator::workstation::rsync with no args shows usage and fails" {
  _register_test_ws

  run terminator::workstation::rsync

  assert_failure
  assert_output --partial "Usage:"
}

################################################################################
# Usage functions
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::ssh::usage
@test "terminator::workstation::ssh::usage shows help text" {
  run terminator::workstation::ssh::usage

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "--workstation"
  assert_output --partial "--help"
}

# bats test_tags=terminator::workstation,terminator::workstation::scp::usage
@test "terminator::workstation::scp::usage shows help text" {
  run terminator::workstation::scp::usage

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "--workstation"
}

# bats test_tags=terminator::workstation,terminator::workstation::rsync::usage
@test "terminator::workstation::rsync::usage shows help text" {
  run terminator::workstation::rsync::usage

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "Excludes:"
}

################################################################################
# Function existence
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::functions
@test "all public functions exist" {
  local functions=(
    terminator::workstation::register
    terminator::workstation::use
    terminator::workstation::list
    terminator::workstation::ssh
    terminator::workstation::scp
    terminator::workstation::rsync
    terminator::workstation::ssh::usage
    terminator::workstation::scp::usage
    terminator::workstation::rsync::usage
    terminator::workstation::provider::gcp::auth
    terminator::workstation::provider::gcp::configure
    terminator::workstation::provider::gcp::ssh
    terminator::workstation::provider::gcp::scp
    terminator::workstation::provider::gcp::rsync_export_env
    terminator::workstation::provider::gcp::rsync_rsh
    terminator::workstation::provider::gcp::format_info
    terminator::workstation::__completion__
    terminator::workstation::__use_completion__
    terminator::workstation::__enable__
    terminator::workstation::__disable__
    terminator::workstation::__export__
    terminator::workstation::__recall__
  )

  local func
  for func in "${functions[@]}"; do
    declare -F "${func}" >/dev/null 2>&1 || {
      echo "MISSING: ${func}" >&2
      return 1
    }
  done
}
