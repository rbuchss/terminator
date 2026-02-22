#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/kubectl.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::kubectl::cluster::add::usage
################################################################################

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add::usage
@test "terminator::kubectl::cluster::add::usage" {
  run terminator::kubectl::cluster::add::usage

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial '--provider'
  assert_output --partial '--help'
  assert_output --partial 'aws'
  assert_output --partial 'azure'
  assert_output --partial 'gcloud'
  assert_output --partial 'hosted'
}

################################################################################
# terminator::kubectl::cluster::add
################################################################################

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add
@test "terminator::kubectl::cluster::add --help" {
  run --separate-stderr terminator::kubectl::cluster::add --help

  assert_success
  assert_stderr --partial 'Usage:'
  assert_stderr --partial '--provider'
}

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add
@test "terminator::kubectl::cluster::add with-invalid-provider" {
  run --separate-stderr terminator::kubectl::cluster::add --provider invalid

  assert_failure 1
  assert_stderr --partial 'ERROR:'
  assert_stderr --partial 'invalid provider option'
}

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add
@test "terminator::kubectl::cluster::add with-no-provider" {
  run --separate-stderr terminator::kubectl::cluster::add

  assert_failure 1
  assert_stderr --partial 'ERROR:'
  assert_stderr --partial 'invalid provider option'
}

################################################################################
# terminator::kubectl::cluster::add::{aws,azure,hosted}
################################################################################

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add::aws
@test "terminator::kubectl::cluster::add::aws" {
  run --separate-stderr terminator::kubectl::cluster::add::aws

  assert_failure 1
  assert_stderr --partial 'ERROR - aws not implemented'
}

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add::azure
@test "terminator::kubectl::cluster::add::azure" {
  run --separate-stderr terminator::kubectl::cluster::add::azure

  assert_failure 1
  assert_stderr --partial 'ERROR - azure not implemented'
}

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::add::hosted
@test "terminator::kubectl::cluster::add::hosted" {
  run --separate-stderr terminator::kubectl::cluster::add::hosted

  assert_failure 1
  assert_stderr --partial 'ERROR - hosted not implemented'
}

################################################################################
# terminator::kubectl::cluster::remove::usage
################################################################################

# bats test_tags=terminator::kubectl,terminator::kubectl::cluster::remove::usage
@test "terminator::kubectl::cluster::remove::usage" {
  run terminator::kubectl::cluster::remove::usage

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial '--cluster'
  assert_output --partial '--help'
}

################################################################################
# terminator::kubectl::config::backup
################################################################################

# bats test_tags=terminator::kubectl,terminator::kubectl::config::backup
@test "terminator::kubectl::config::backup with-existing-config" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_dir}"

  mkdir -p "${temp_dir}/.kube"
  echo 'test-config-content' >"${temp_dir}/.kube/config"

  run terminator::kubectl::config::backup

  HOME="${original_home}"

  assert_success
  # Verify backup directory was created
  [[ -d "${temp_dir}/.kube/backups" ]]
  # Verify a backup file exists
  local backup_count
  backup_count="$(find "${temp_dir}/.kube/backups/" -maxdepth 1 -type f | wc -l)"
  ((backup_count > 0))

  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::kubectl,terminator::kubectl::config::backup
@test "terminator::kubectl::config::backup with-no-config-file" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_dir}"

  mkdir -p "${temp_dir}/.kube"
  # Do NOT create a config file

  run --separate-stderr terminator::kubectl::config::backup

  HOME="${original_home}"

  assert_failure 1

  rm -rf "${temp_dir}"
}
