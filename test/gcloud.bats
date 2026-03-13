#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/gcloud.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::gcloud::alias_completion
################################################################################

# bats test_tags=terminator::gcloud,terminator::gcloud::alias_completion
@test "terminator::gcloud::alias_completion function-exists" {
  run type -t terminator::gcloud::alias_completion

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::gcloud::auth
################################################################################

# bats test_tags=terminator::gcloud,terminator::gcloud::auth
@test "terminator::gcloud::auth function-exists" {
  run type -t terminator::gcloud::auth

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::gcloud,terminator::gcloud::auth
@test "terminator::gcloud::auth with active account" {
  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud {
    case "$1" in
      auth)
        case "$2" in
          list) echo "user@example.com" ;;
          print-access-token) return 0 ;;
        esac
        ;;
    esac
  }

  run terminator::gcloud::auth

  assert_success
  assert_output --partial "Authenticated with gcloud as:"
}

# bats test_tags=terminator::gcloud,terminator::gcloud::auth
@test "terminator::gcloud::auth with no active account triggers login" {
  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud {
    case "$1" in
      auth)
        case "$2" in
          list) echo "" ;;
          login)
            echo "logged-in"
            return 0
            ;;
        esac
        ;;
    esac
  }

  run terminator::gcloud::auth

  assert_success
  assert_output --partial "No active gcloud authentication found"
}

# bats test_tags=terminator::gcloud,terminator::gcloud::auth
@test "terminator::gcloud::auth with expired tokens re-authenticates" {
  # shellcheck disable=SC2317 # invoked indirectly
  function gcloud {
    case "$1" in
      auth)
        case "$2" in
          list) echo "user@example.com" ;;
          print-access-token) return 1 ;;
          login)
            echo "re-authed"
            return 0
            ;;
        esac
        ;;
    esac
  }

  run terminator::gcloud::auth

  assert_success
  assert_output --partial "Gcloud tokens expired"
}

################################################################################
# terminator::gcloud::__enable__
################################################################################

# bats test_tags=terminator::gcloud,terminator::gcloud::__enable__
@test "terminator::gcloud::__enable__ function-exists" {
  run type -t terminator::gcloud::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::gcloud,terminator::gcloud::__enable__
@test "terminator::gcloud::__enable__ when-gcloud-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::gcloud::__enable__

  # Returns early with failure when gcloud not found
  assert_failure
}

# bats test_tags=terminator::gcloud,terminator::gcloud::__enable__
@test "terminator::gcloud::__enable__ when-gcloud-available" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create fake SDK root with completion file
  mkdir -p "${tmp_dir}/sdk"
  echo "# gcloud completion stub" >"${tmp_dir}/sdk/completion.bash.inc"

  # Create stub gcloud that returns our fake SDK root
  cat >"${tmp_dir}/gcloud" <<STUB
#!/bin/sh
echo "${tmp_dir}/sdk"
STUB
  chmod +x "${tmp_dir}/gcloud"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  PATH="${tmp_dir}:${PATH}"
  run terminator::gcloud::__enable__

  assert_success

  rm -rf "${tmp_dir}"
}
