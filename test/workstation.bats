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
# Helper: register a test workstation with SSH provider
################################################################################

_register_ssh_ws() {
  terminator::workstation::register \
    --name ssh-ws \
    --provider ssh \
    --host 10.0.0.42 \
    --user testuser \
    --key /tmp/test_key \
    --port 2222
}

_register_ssh_ws_minimal() {
  terminator::workstation::register \
    --name ssh-ws-min \
    --provider ssh \
    --host 10.0.0.99
}

################################################################################
# terminator::workstation::register
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register requires --name" {
  run terminator::workstation::register --provider gcp

  assert_failure
  assert_output --partial '--name is required'
}

# bats test_tags=terminator::workstation,terminator::workstation::register
@test "terminator::workstation::register requires --provider" {
  run terminator::workstation::register --name test-ws

  assert_failure
  assert_output --partial '--provider is required'
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
  assert_output --partial "'nonexistent' is not a registered workstation"
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
# GCP provider: get_external_ip (mocked gcloud)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::gcp::get_external_ip
@test "provider::gcp::get_external_ip calls gcloud with correct args" {
  _register_test_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::provider::gcp::get_external_ip "test-ws"

  assert_success
  assert_output "gcloud compute instances describe test-ws --zone us-east1-c --project test-project --format=get(networkInterfaces[0].accessConfigs[0].natIP)"
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
# SSH provider: configure
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::configure
@test "provider::ssh::configure stores host, user, key, port" {
  _register_ssh_ws

  [[ "${TERMINATOR_WORKSTATION_SSH_HOSTS[0]}" == "10.0.0.42" ]]
  [[ "${TERMINATOR_WORKSTATION_SSH_USERS[0]}" == "testuser" ]]
  [[ "${TERMINATOR_WORKSTATION_SSH_KEYS[0]}" == "/tmp/test_key" ]]
  [[ "${TERMINATOR_WORKSTATION_SSH_PORTS[0]}" == "2222" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::configure
@test "provider::ssh::configure defaults port to 22" {
  _register_ssh_ws_minimal

  [[ "${TERMINATOR_WORKSTATION_SSH_PORTS[0]}" == "22" ]]
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::configure
@test "provider::ssh::configure requires --name" {
  run terminator::workstation::provider::ssh::configure --host 10.0.0.1

  assert_failure
  assert_output --partial '--name is required'
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::configure
@test "provider::ssh::configure requires --host" {
  terminator::workstation::register --name bare-ws --provider fake_provider

  run terminator::workstation::provider::ssh::configure --name bare-ws

  assert_failure
  assert_output --partial '--host is required'
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::configure
@test "provider::ssh::configure fails for unregistered name" {
  run terminator::workstation::provider::ssh::configure --name nonexistent --host 10.0.0.1

  assert_failure
  assert_output --partial "'nonexistent' is not registered"
}

################################################################################
# SSH provider: format_info
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::format_info
@test "provider::ssh::format_info outputs host and user" {
  _register_ssh_ws

  run terminator::workstation::provider::ssh::format_info "ssh-ws"

  assert_success
  assert_output "host: 10.0.0.42, user: testuser, port: 2222"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::format_info
@test "provider::ssh::format_info omits port when 22" {
  _register_ssh_ws_minimal

  run terminator::workstation::provider::ssh::format_info "ssh-ws-min"

  assert_success
  assert_output "host: 10.0.0.99"
}

################################################################################
# SSH provider: ssh (mocked ssh)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::ssh
@test "provider::ssh::ssh calls ssh with correct args" {
  _register_ssh_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "ssh $*"; }

  run terminator::workstation::provider::ssh::ssh "ssh-ws" ls -la

  assert_success
  assert_output "ssh -i /tmp/test_key -p 2222 testuser@10.0.0.42 ls -la"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::ssh
@test "provider::ssh::ssh works without user or key" {
  _register_ssh_ws_minimal

  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "ssh $*"; }

  run terminator::workstation::provider::ssh::ssh "ssh-ws-min"

  assert_success
  assert_output "ssh -p 22 10.0.0.99"
}

################################################################################
# SSH provider: scp (mocked scp)
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::scp
@test "provider::ssh::scp calls scp with correct args and rewrites paths" {
  _register_ssh_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function scp { echo "scp $*"; }

  run terminator::workstation::provider::ssh::scp "ssh-ws" "ssh-ws:~/remote-file" "./local"

  assert_success
  assert_output "scp -i /tmp/test_key -P 2222 testuser@10.0.0.42:~/remote-file ./local"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::scp
@test "provider::ssh::scp rewrites only matching instance prefix" {
  _register_ssh_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function scp { echo "scp $*"; }

  run terminator::workstation::provider::ssh::scp "ssh-ws" "./local" "ssh-ws:~/remote"

  assert_success
  assert_output "scp -i /tmp/test_key -P 2222 ./local testuser@10.0.0.42:~/remote"
}

################################################################################
# SSH provider: rsync_export_env
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::rsync_export_env
@test "provider::ssh::rsync_export_env exports env vars" {
  _register_ssh_ws

  terminator::workstation::provider::ssh::rsync_export_env "ssh-ws"

  [[ "${__TERMINATOR_RSYNC_SSH_HOST__}" == "10.0.0.42" ]]
  [[ "${__TERMINATOR_RSYNC_SSH_USER__}" == "testuser" ]]
  [[ "${__TERMINATOR_RSYNC_SSH_KEY__}" == "/tmp/test_key" ]]
  [[ "${__TERMINATOR_RSYNC_SSH_PORT__}" == "2222" ]]
}

################################################################################
# SSH provider: list shows SSH details
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::list
@test "terminator::workstation::list shows SSH details" {
  _register_ssh_ws

  run terminator::workstation::list

  assert_success
  assert_output --partial "host: 10.0.0.42, user: testuser, port: 2222"
}

################################################################################
# SSH provider: get_external_ip
################################################################################

################################################################################
# SSH provider: __resolve_ssh_config__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_ssh_config__
@test "__resolve_ssh_config__ resolves host alias to IP" {
  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname 192.168.1.50"; }

  run terminator::workstation::provider::ssh::__resolve_ssh_config__ "my-alias"

  assert_success
  assert_output "192.168.1.50"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_ssh_config__
@test "__resolve_ssh_config__ resolves host alias to DNS name" {
  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname actual.example.com"; }

  run terminator::workstation::provider::ssh::__resolve_ssh_config__ "my-alias"

  assert_success
  assert_output "actual.example.com"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_ssh_config__
@test "__resolve_ssh_config__ returns 1 when hostname unchanged" {
  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname example.test"; }

  run terminator::workstation::provider::ssh::__resolve_ssh_config__ "example.test"

  assert_failure
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_ssh_config__
@test "__resolve_ssh_config__ returns 1 when ssh unavailable" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::workstation::provider::ssh::__resolve_ssh_config__ "my-alias"

  assert_failure
}

################################################################################
# SSH provider: __resolve_dns__
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_dns__
@test "__resolve_dns__ resolves via getent" {
  # shellcheck disable=SC2317 # invoked indirectly
  function getent { echo "93.184.216.34  example.test"; }

  run terminator::workstation::provider::ssh::__resolve_dns__ "example.test"

  assert_success
  assert_output "93.184.216.34"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_dns__
@test "__resolve_dns__ resolves via nslookup" {
  # Hide getent so nslookup is tried
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists {
    [[ "$1" == 'getent' ]] && return 1
    command -v "$1" >/dev/null 2>&1
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function nslookup { echo "Address: 93.184.216.34"; }

  run terminator::workstation::provider::ssh::__resolve_dns__ "example.test"

  assert_success
  assert_output "93.184.216.34"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_dns__
@test "__resolve_dns__ resolves via dig" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists {
    [[ "$1" == 'getent' || "$1" == 'nslookup' ]] && return 1
    command -v "$1" >/dev/null 2>&1
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function dig { echo "93.184.216.34"; }

  run terminator::workstation::provider::ssh::__resolve_dns__ "example.test"

  assert_success
  assert_output "93.184.216.34"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_dns__
@test "__resolve_dns__ resolves via host" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists {
    [[ "$1" == 'getent' || "$1" == 'nslookup' || "$1" == 'dig' ]] && return 1
    command -v "$1" >/dev/null 2>&1
  }
  # shellcheck disable=SC2317 # invoked indirectly
  function host { echo "example.test has address 93.184.216.34"; }

  run terminator::workstation::provider::ssh::__resolve_dns__ "example.test"

  assert_success
  assert_output "93.184.216.34"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_dns__
@test "__resolve_dns__ returns 1 when no tools available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::workstation::provider::ssh::__resolve_dns__ "example.test"

  assert_failure
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::__resolve_dns__
@test "__resolve_dns__ returns 1 when resolution fails" {
  # shellcheck disable=SC2317 # invoked indirectly
  function getent { return 2; }

  run terminator::workstation::provider::ssh::__resolve_dns__ "nonexistent.invalid"

  assert_failure
}

################################################################################
# SSH provider: get_external_ip
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::get_external_ip
@test "provider::ssh::get_external_ip returns IP directly when configured with IP" {
  _register_ssh_ws

  run terminator::workstation::provider::ssh::get_external_ip "ssh-ws"

  assert_success
  assert_output "10.0.0.42"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::get_external_ip
@test "provider::ssh::get_external_ip resolves SSH config to IP" {
  terminator::workstation::register \
    --name ssh-alias-ws \
    --provider ssh \
    --host my-server-alias

  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname 192.168.1.50"; }

  run terminator::workstation::provider::ssh::get_external_ip "ssh-alias-ws"

  assert_success
  assert_output "192.168.1.50"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::get_external_ip
@test "provider::ssh::get_external_ip resolves SSH config to DNS then DNS to IP" {
  terminator::workstation::register \
    --name ssh-chain-ws \
    --provider ssh \
    --host my-alias

  # SSH config resolves alias to a DNS name
  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname actual.example.com"; }
  # DNS resolves that name to an IP
  # shellcheck disable=SC2317 # invoked indirectly
  function getent { echo "10.20.30.40  actual.example.com"; }

  run terminator::workstation::provider::ssh::get_external_ip "ssh-chain-ws"

  assert_success
  assert_output "10.20.30.40"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::get_external_ip
@test "provider::ssh::get_external_ip resolves DNS hostname" {
  terminator::workstation::register \
    --name ssh-dns-ws \
    --provider ssh \
    --host example.test

  # ssh -G returns the same hostname (no SSH config match)
  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname example.test"; }
  # Mock all DNS tools to ensure whichever is tried first works
  # shellcheck disable=SC2317 # invoked indirectly
  function getent { echo "93.184.216.34  example.test"; }
  # shellcheck disable=SC2317 # invoked indirectly
  function nslookup { echo "Address: 93.184.216.34"; }
  # shellcheck disable=SC2317 # invoked indirectly
  function dig { echo "93.184.216.34"; }
  # shellcheck disable=SC2317 # invoked indirectly
  function host { echo "example.test has address 93.184.216.34"; }

  run terminator::workstation::provider::ssh::get_external_ip "ssh-dns-ws"

  assert_success
  assert_output "93.184.216.34"
}

# bats test_tags=terminator::workstation,terminator::workstation::provider::ssh::get_external_ip
@test "provider::ssh::get_external_ip falls back to host when unresolvable" {
  terminator::workstation::register \
    --name ssh-noip-ws \
    --provider ssh \
    --host unresolvable.invalid

  # ssh -G returns the same hostname
  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "hostname unresolvable.invalid"; }
  # No DNS tools can resolve it
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists {
    case "$1" in
      ssh) return 0 ;;
      getent | nslookup | dig | host) return 1 ;;
      *) command -v "$1" >/dev/null 2>&1 ;;
    esac
  }

  run terminator::workstation::provider::ssh::get_external_ip "ssh-noip-ws"

  assert_success
  assert_output --partial "unresolvable.invalid"
}

################################################################################
# SSH provider: dispatch through core ssh
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh dispatches to ssh provider" {
  _register_ssh_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function ssh { echo "ssh $*"; }

  run terminator::workstation::ssh ls -la

  assert_success
  assert_output "ssh -i /tmp/test_key -p 2222 testuser@10.0.0.42 ls -la"
}

# bats test_tags=terminator::workstation,terminator::workstation::scp
@test "terminator::workstation::scp dispatches to ssh provider" {
  _register_ssh_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function scp { echo "scp $*"; }

  run terminator::workstation::scp "ssh-ws:~/remote" "./local"

  assert_success
  assert_output "scp -i /tmp/test_key -P 2222 testuser@10.0.0.42:~/remote ./local"
}

################################################################################
# Dispatch: ip
################################################################################

# bats test_tags=terminator::workstation,terminator::workstation::ip
@test "terminator::workstation::ip dispatches to gcp provider" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::gcloud::auth { :; }
  _register_test_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::ip

  assert_success
  assert_output --partial "gcloud compute instances describe test-ws --zone us-east1-c --project test-project"
}

# bats test_tags=terminator::workstation,terminator::workstation::ip
@test "terminator::workstation::ip with -w flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::gcloud::auth { :; }
  _register_two_ws

  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud { echo "gcloud $*"; }

  run terminator::workstation::ip -w dev-ws

  assert_success
  assert_output --partial "gcloud compute instances describe dev-ws --zone us-central1-a --project dev-project"
}

# bats test_tags=terminator::workstation,terminator::workstation::ip
@test "terminator::workstation::ip --help shows usage" {
  _register_test_ws

  run terminator::workstation::ip --help

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "--workstation"
}

# bats test_tags=terminator::workstation,terminator::workstation::ip
@test "terminator::workstation::ip fails with no workstation and no default" {
  TERMINATOR_WORKSTATION_CURRENT=""

  run terminator::workstation::ip

  assert_failure
  assert_output --partial 'no workstation specified and no default set'
}

# bats test_tags=terminator::workstation,terminator::workstation::ip
@test "terminator::workstation::ip fails for unsupported provider" {
  terminator::workstation::register \
    --name test-ws \
    --provider fake_provider

  run terminator::workstation::ip

  assert_failure
  assert_output --partial "does not support get_external_ip"
}

# bats test_tags=terminator::workstation,terminator::workstation::ip::usage
@test "terminator::workstation::ip::usage shows help text" {
  run terminator::workstation::ip::usage

  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "--workstation"
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
  assert_output --partial 'no workstation specified and no default set'
}

# bats test_tags=terminator::workstation,terminator::workstation::ssh
@test "terminator::workstation::ssh fails for unregistered workstation" {
  _register_test_ws

  run terminator::workstation::ssh -w nonexistent

  assert_failure
  assert_output --partial "'nonexistent' is not a registered workstation"
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
    terminator::workstation::ip
    terminator::workstation::ip::usage
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
    terminator::workstation::provider::gcp::get_external_ip
    terminator::workstation::provider::gcp::format_info
    terminator::workstation::provider::ssh::configure
    terminator::workstation::provider::ssh::__build_flags__
    terminator::workstation::provider::ssh::__build_dest__
    terminator::workstation::provider::ssh::ssh
    terminator::workstation::provider::ssh::scp
    terminator::workstation::provider::ssh::rsync_export_env
    terminator::workstation::provider::ssh::rsync_rsh
    terminator::workstation::provider::ssh::get_external_ip
    terminator::workstation::provider::ssh::format_info
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
