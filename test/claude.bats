#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/claude.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::claude::__require_claude__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::__require_claude__
@test "terminator::claude::__require_claude__ returns 0 when claude exists" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::__require_claude__

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::__require_claude__
@test "terminator::claude::__require_claude__ returns 1 when claude missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::__require_claude__

  assert_failure
  assert_output --partial 'claude is not installed'
}

# bats test_tags=terminator::claude,terminator::claude::__require_claude__
@test "terminator::claude::__require_claude__ includes optional message" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::__require_claude__ 'my-plugin'

  assert_failure
  assert_output --partial 'my-plugin'
}

################################################################################
# terminator::claude::__enable__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::__enable__
@test "terminator::claude::__enable__ when-local-bin-missing" {
  local original_home="${HOME}"
  HOME="$(mktemp -d)/nonexistent"

  run terminator::claude::__enable__

  HOME="${original_home}"

  assert_failure 1
}

# bats test_tags=terminator::claude,terminator::claude::__enable__
@test "terminator::claude::__enable__ when-claude-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  local temp_home
  temp_home="$(mktemp -d)"
  mkdir -p "${temp_home}/.local/bin"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::__enable__

  HOME="${original_home}"

  assert_failure 1

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::__enable__
@test "terminator::claude::__enable__ removes-user-scope-serena" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::claude::settings::merge_baseline { return 0; }

  # The context7 version matches so its sync is a no-op, and the user-scope
  # serena entry drives the removal, leaving it as the only mcp mutation.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove)
            echo "removed: $*"
            return 0
            ;;
          add)
            echo 'should not be called'
            return 1
            ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  mkdir -p "${temp_home}/.local/bin"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]},"serena":{"command":"uvx","args":["--from","serena-agent==9.9.9"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::__enable__

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'removed: remove --scope user serena'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::__enable__
@test "terminator::claude::__enable__ user-scope-removal-never-touches-other-scopes" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::claude::settings::merge_baseline { return 0; }

  # Only the user-scope serena removal may run: local and project scope opt-ins
  # are user data and must survive the self-migration.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove)
            if [[ "$*" == 'remove --scope user serena' ]]; then
              return 0
            fi
            echo "should not be called: $*"
            return 1
            ;;
          *)
            echo "should not be called: $*"
            return 1
            ;;
        esac
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_home \
    repo_root \
    original_home="${HOME}"
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  mkdir -p "${temp_home}/.local/bin"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]},"serena":{"command":"uvx","args":["--from","serena-agent==9.9.9"]}},"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  HOME="${temp_home}"

  run terminator::claude::__enable__

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::__disable__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::__disable__
@test "terminator::claude::__disable__ runs-without-error" {
  run terminator::claude::__disable__

  assert_success
}

################################################################################
# terminator::claude::mcp::enable::context7
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 function-exists" {
  run type -t terminator::claude::mcp::enable::context7

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::enable::context7

  assert_failure
  assert_output --partial 'context7'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::mcp::enable::context7 --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 skips-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  # The user-scope entry already matches the pinned version, so no claude
  # call is made at all.
  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::context7

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 force-readds-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::context7 --force

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 adds-at-user-scope-by-default" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove)
            echo "removed: $*"
            return 0
            ;;
          add)
            echo "added: $*"
            return 0
            ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::context7

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'added: add --scope user context7 -- bunx -y @upstash/context7-mcp@4.4.4'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 adds-at-project-scope-with-flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add)
            echo "added: $*"
            return 0
            ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::context7 --project

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'added: add --scope project context7 -- bunx -y @upstash/context7-mcp@4.4.4'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 skips-at-project-scope-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local \
    temp_repo \
    original_dir="${PWD}"
  temp_repo="$(mktemp -d)"
  git init -q "${temp_repo}"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_repo}/.mcp.json"
  cd "${temp_repo}"

  run terminator::claude::mcp::enable::context7 --project

  cd "${original_dir}"
  rm -rf "${temp_repo}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 fails-outside-repo-for-project-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::enable::context7 --project

  cd "${original_dir}"
  rm -rf "${temp_dir}"

  assert_failure
  assert_output --partial 'not inside a git repo'
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::mcp::disable::context7
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 function-exists" {
  run type -t terminator::claude::mcp::disable::context7

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::disable::context7

  assert_failure
  assert_output --partial 'context7'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Only --project is accepted; --version has no meaning for a removal.
  run terminator::claude::mcp::disable::context7 --version 4.4.4

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 removes-user-scope-by-default" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope user context7') echo 'removed user context7' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::disable::context7

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output 'removed user context7'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 removes-project-scope-with-flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope project context7') echo 'removed project context7' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_repo \
    original_dir="${PWD}"
  temp_repo="$(mktemp -d)"
  git init -q "${temp_repo}"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_repo}/.mcp.json"
  cd "${temp_repo}"

  run terminator::claude::mcp::disable::context7 --project

  cd "${original_dir}"
  rm -rf "${temp_repo}"

  assert_success
  assert_output 'removed project context7'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 fails-outside-repo-for-project-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::disable::context7 --project

  cd "${original_dir}"
  rm -rf "${temp_dir}"

  assert_failure
  assert_output --partial 'not inside a git repo'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::context7
@test "terminator::claude::mcp::disable::context7 succeeds-when-not-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # The removal is idempotent: with no registration at the scope, the config
  # gate skips the CLI call entirely.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 1; }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::disable::context7

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

################################################################################
# terminator::claude::mcp::__parse_scope_options__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_scope_options__
@test "terminator::claude::mcp::__parse_scope_options__ defaults-to-passed-scope" {
  local force version scope

  terminator::claude::mcp::__parse_scope_options__ force version scope local

  [[ "${force}" == 0 ]]
  [[ -z "${version}" ]]
  [[ "${scope}" == 'local' ]]

  terminator::claude::mcp::__parse_scope_options__ force version scope user

  [[ "${force}" == 0 ]]
  [[ -z "${version}" ]]
  [[ "${scope}" == 'user' ]]
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_scope_options__
@test "terminator::claude::mcp::__parse_scope_options__ captures-force-version-and-project" {
  local force version scope

  terminator::claude::mcp::__parse_scope_options__ force version scope local \
    --project --force --version 1.2.3

  [[ "${force}" == 1 ]]
  [[ "${version}" == 1.2.3 ]]
  [[ "${scope}" == 'project' ]]
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_scope_options__
@test "terminator::claude::mcp::__parse_scope_options__ when-unknown-option" {
  local force version scope

  run terminator::claude::mcp::__parse_scope_options__ force version scope local --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

################################################################################
# terminator::claude::mcp::__parse_scope_flag__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_scope_flag__
@test "terminator::claude::mcp::__parse_scope_flag__ defaults-to-passed-scope" {
  local scope

  terminator::claude::mcp::__parse_scope_flag__ scope local
  [[ "${scope}" == 'local' ]]

  terminator::claude::mcp::__parse_scope_flag__ scope user
  [[ "${scope}" == 'user' ]]
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_scope_flag__
@test "terminator::claude::mcp::__parse_scope_flag__ project-flag-overrides-default" {
  local scope

  terminator::claude::mcp::__parse_scope_flag__ scope user --project

  [[ "${scope}" == 'project' ]]
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_scope_flag__
@test "terminator::claude::mcp::__parse_scope_flag__ when-unknown-option" {
  local scope

  # Force and version have no meaning for a removal.
  run terminator::claude::mcp::__parse_scope_flag__ scope user --version 1.2.3

  assert_failure
  assert_output --partial 'unknown option'
}

################################################################################
# terminator::claude::mcp::__configured_command__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ prints-user-scope-command" {
  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__configured_command__ context7 user

  HOME="${original_home}"

  assert_success
  assert_output 'bunx -y @upstash/context7-mcp@4.4.4'

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ prints-local-scope-command" {
  local \
    temp_home \
    repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__configured_command__ serena local "${repo_root}"

  HOME="${original_home}"

  assert_success
  assert_output 'uvx --from serena-agent==2.1.0'

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ prints-project-scope-command" {
  local \
    temp_repo \
    original_dir="${PWD}"
  temp_repo="$(mktemp -d)"
  git init -q "${temp_repo}"
  printf '{"mcpServers":{"foo":{"command":"echo","args":["hi"]}}}\n' \
    >"${temp_repo}/.mcp.json"
  cd "${temp_repo}"

  run terminator::claude::mcp::__configured_command__ foo project

  cd "${original_dir}"

  assert_success
  assert_output 'echo hi'

  rm -rf "${temp_repo}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ yields-nothing-when-entry-absent" {
  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"other":{"command":"echo"}}}\n' >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__configured_command__ context7 user

  HOME="${original_home}"

  assert_success
  assert_output ''

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ yields-nothing-when-file-absent" {
  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__configured_command__ context7 user

  HOME="${original_home}"

  assert_success
  assert_output ''

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ never-prints-env" {
  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.23.1"],"env":{"JIRA_API_TOKEN":"secret-token"}}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__configured_command__ atlassian user

  HOME="${original_home}"

  assert_success
  assert_output 'uvx mcp-atlassian==0.23.1'
  refute_output --partial 'secret-token'

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ respects-claude-config-dir" {
  local \
    temp_config \
    original_config_dir="${CLAUDE_CONFIG_DIR}"
  temp_config="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_config}/.claude.json"
  export CLAUDE_CONFIG_DIR="${temp_config}"

  run terminator::claude::mcp::__configured_command__ context7 user

  if [[ -n "${original_config_dir}" ]]; then
    export CLAUDE_CONFIG_DIR="${original_config_dir}"
  else
    unset CLAUDE_CONFIG_DIR
  fi

  assert_success
  assert_output 'bunx -y @upstash/context7-mcp@4.4.4'

  rm -rf "${temp_config}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__configured_command__
@test "terminator::claude::mcp::__configured_command__ when-unknown-scope" {
  run terminator::claude::mcp::__configured_command__ foo bogus

  assert_failure
  assert_output --partial 'unknown scope'
}

################################################################################
# terminator::claude::mcp::__remove__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__remove__
@test "terminator::claude::mcp::__remove__ calls-remove-with-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope local serena') echo 'removed serena' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_home \
    repo_root \
    original_dir="${PWD}"
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"
  cd "${repo_root}"

  run terminator::claude::mcp::__remove__ serena local

  cd "${original_dir}"
  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output 'removed serena'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__remove__
@test "terminator::claude::mcp::__remove__ skips-cli-when-not-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # With no registration at the scope, the config gate skips the CLI call
  # entirely: the steady state makes no claude calls at all.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__remove__ serena local

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__remove__
@test "terminator::claude::mcp::__remove__ succeeds-when-server-absent" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # The removal is idempotent: with no registration at the scope, the config
  # gate skips the CLI call entirely, and a failing CLI could not break it
  # either.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 1; }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::__remove__ serena local

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__remove__
@test "terminator::claude::mcp::__remove__ when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::__remove__ serena local

  assert_failure
  assert_output --partial 'serena'
}

################################################################################
# terminator::claude::mcp::__project_root__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__project_root__
@test "terminator::claude::mcp::__project_root__ returns-repo-root-inside-repo" {
  local expected
  expected="$(git rev-parse --show-toplevel)"

  run terminator::claude::mcp::__project_root__ local

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__project_root__
@test "terminator::claude::mcp::__project_root__ falls-back-to-pwd-outside-repo" {
  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::__project_root__ local

  assert_success
  assert_output "${temp_dir}"

  cd "${original_dir}"
  rm -rf "${temp_dir}"
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__project_root__
@test "terminator::claude::mcp::__project_root__ fails-outside-repo-for-project-scope" {
  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::__project_root__ project

  assert_failure
  assert_output --partial 'not inside a git repo'

  cd "${original_dir}"
  rm -rf "${temp_dir}"
}

################################################################################
# terminator::claude::mcp::enable::serena
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena function-exists" {
  run type -t terminator::claude::mcp::enable::serena

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::enable::serena

  assert_failure
  assert_output --partial 'serena'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::mcp::enable::serena --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena adds-at-local-scope-by-default" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove)
            echo "removed: $*"
            return 0
            ;;
          add)
            echo "added: $*"
            return 0
            ;;
        esac
        ;;
    esac
  }

  # The user-scope entry drives the strip; no local entry exists yet.
  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==9.9.9"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::serena

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'removed: remove --scope user serena'
  assert_output --partial 'added: add --scope local serena -- uvx --from serena-agent==2.1.0'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena skips-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  # The local entry already matches the pinned version, so no claude call is
  # made at all; with no user-scope entry, even the strip is skipped.
  local \
    temp_home \
    repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::serena

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena force-readds-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add)
            echo "added: $*"
            return 0
            ;;
        esac
        ;;
    esac
  }

  local \
    temp_home \
    repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::serena --force

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'added: add --scope local serena -- uvx --from serena-agent==2.1.0'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena version-override-readds-on-mismatch" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add)
            echo "added: $*"
            return 0
            ;;
        esac
        ;;
    esac
  }

  local \
    temp_home \
    repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::serena --version 9.9.9

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'added: add --scope local serena -- uvx --from serena-agent==9.9.9'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena removes-user-scope-remnant-first" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # A user-scope remnant must be removed so the opt-in owns the entry. The
  # local entry already matches the pinned version, so nothing else may run.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope user serena') return 0 ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_home \
    repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==9.9.9"]}},"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::serena

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena adds-at-project-scope-with-flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          add)
            echo "added: $*"
            return 0
            ;;
          *)
            echo 'should not be called'
            return 1
            ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::serena --project

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output --partial 'added: add --scope project serena -- uvx --from serena-agent==2.1.0'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::serena
@test "terminator::claude::mcp::enable::serena fails-outside-repo-for-project-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::enable::serena --project

  cd "${original_dir}"
  rm -rf "${temp_dir}"

  assert_failure
  assert_output --partial 'not inside a git repo'
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::mcp::disable::serena
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena function-exists" {
  run type -t terminator::claude::mcp::disable::serena

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::disable::serena

  assert_failure
  assert_output --partial 'serena'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Only --project is accepted; --version has no meaning for a removal.
  run terminator::claude::mcp::disable::serena --version 2.1.0

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena removes-local-scope-by-default" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope local serena') echo 'removed local serena' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_home \
    repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  temp_home="$(mktemp -d)"
  printf '{"projects":{"%s":{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}}}\n' \
    "${repo_root}" >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::disable::serena

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output 'removed local serena'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena removes-project-scope-with-flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope project serena') echo 'removed project serena' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_repo \
    original_dir="${PWD}"
  temp_repo="$(mktemp -d)"
  git init -q "${temp_repo}"
  printf '{"mcpServers":{"serena":{"command":"uvx","args":["--from","serena-agent==2.1.0"]}}}\n' \
    >"${temp_repo}/.mcp.json"
  cd "${temp_repo}"

  run terminator::claude::mcp::disable::serena --project

  cd "${original_dir}"
  rm -rf "${temp_repo}"

  assert_success
  assert_output 'removed project serena'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena fails-outside-repo-for-project-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::disable::serena --project

  cd "${original_dir}"
  rm -rf "${temp_dir}"

  assert_failure
  assert_output --partial 'not inside a git repo'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::serena
@test "terminator::claude::mcp::disable::serena succeeds-when-not-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # The removal is idempotent: with no registration at the scope, the config
  # gate skips the CLI call entirely.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 1; }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::disable::serena

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

################################################################################
# terminator::claude::mcp::enable::atlassian
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian function-exists" {
  run type -t terminator::claude::mcp::enable::atlassian

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::enable::atlassian

  assert_failure
  assert_output --partial 'mcp-atlassian'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian when-all-env-vars-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  unset JIRA_URL JIRA_USERNAME JIRA_API_TOKEN \
    CONFLUENCE_URL CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN

  run terminator::claude::mcp::enable::atlassian

  assert_failure
  assert_output --partial 'missing env vars'
  assert_output --partial 'JIRA_URL'
  assert_output --partial 'CONFLUENCE_API_TOKEN'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian when-partial-env-vars-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  unset CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN

  run terminator::claude::mcp::enable::atlassian

  assert_failure
  assert_output --partial 'missing env vars'
  assert_output --partial 'CONFLUENCE_USERNAME'
  assert_output --partial 'CONFLUENCE_API_TOKEN'
  refute_output --partial 'JIRA_URL'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  run terminator::claude::mcp::enable::atlassian --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian adds-when-not-installed" {
  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  local __add_called__=false

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          add) __add_called__=true ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::atlassian

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian skips-when-version-matches" {
  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  # The user-scope entry already matches the pinned version, so no claude
  # call is made at all.
  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.23.1"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::atlassian

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian force-readds-when-version-matches" {
  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.23.1"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::atlassian --force

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian updates-when-version-mismatches" {
  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.19.0"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::atlassian

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

################################################################################
# terminator::claude::mcp::disable::atlassian
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian function-exists" {
  run type -t terminator::claude::mcp::disable::atlassian

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::disable::atlassian

  assert_failure
  assert_output --partial 'mcp-atlassian'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Only --project is accepted; --version has no meaning for a removal.
  run terminator::claude::mcp::disable::atlassian --version 0.23.1

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian removes-user-scope-by-default" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # No env vars are needed for a removal.
  unset JIRA_URL JIRA_USERNAME JIRA_API_TOKEN \
    CONFLUENCE_URL CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope user atlassian') echo 'removed user atlassian' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.23.1"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::disable::atlassian

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  assert_output 'removed user atlassian'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian removes-project-scope-with-flag" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope project atlassian') echo 'removed project atlassian' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_repo \
    original_dir="${PWD}"
  temp_repo="$(mktemp -d)"
  git init -q "${temp_repo}"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.23.1"]}}}\n' \
    >"${temp_repo}/.mcp.json"
  cd "${temp_repo}"

  run terminator::claude::mcp::disable::atlassian --project

  cd "${original_dir}"
  rm -rf "${temp_repo}"

  assert_success
  assert_output 'removed project atlassian'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian fails-outside-repo-for-project-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local \
    temp_dir \
    original_dir="${PWD}"
  temp_dir="$(mktemp -d)"
  cd "${temp_dir}"

  run terminator::claude::mcp::disable::atlassian --project

  cd "${original_dir}"
  rm -rf "${temp_dir}"

  assert_failure
  assert_output --partial 'not inside a git repo'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::disable::atlassian
@test "terminator::claude::mcp::disable::atlassian succeeds-when-not-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # The removal is idempotent: with no registration at the scope, the config
  # gate skips the CLI call entirely.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 1; }

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::disable::atlassian

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

################################################################################
# terminator::claude::settings::merge_baseline
################################################################################

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline when-jq-not-found" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::settings::merge_baseline

  assert_failure 1
}

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline creates-file-when-missing" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  local original_root="${TERMINATOR_MODULE_ROOT_DIR}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.terminator/config/claude"
  printf '{"statusLine":{"type":"command"}}\n' \
    >"${temp_home}/.terminator/config/claude/settings.base.json"
  TERMINATOR_MODULE_ROOT_DIR="${temp_home}/.terminator"

  run terminator::claude::settings::merge_baseline

  HOME="${original_home}"
  TERMINATOR_MODULE_ROOT_DIR="${original_root}"

  assert_success
  assert [ -f "${temp_home}/.claude/settings.json" ]

  local content
  content="$(cat "${temp_home}/.claude/settings.json")"
  [[ "${content}" == *'"statusLine"'* ]]

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline merges-with-existing" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  local original_root="${TERMINATOR_MODULE_ROOT_DIR}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.terminator/config/claude"
  printf '{"statusLine":{"type":"command","command":"default"}}\n' \
    >"${temp_home}/.terminator/config/claude/settings.base.json"
  TERMINATOR_MODULE_ROOT_DIR="${temp_home}/.terminator"

  mkdir -p "${temp_home}/.claude"
  printf '{"statusLine":{"type":"command","command":"custom"},"extra":"kept"}\n' \
    >"${temp_home}/.claude/settings.json"

  run terminator::claude::settings::merge_baseline

  HOME="${original_home}"
  TERMINATOR_MODULE_ROOT_DIR="${original_root}"

  assert_success

  local content
  content="$(cat "${temp_home}/.claude/settings.json")"
  # existing "custom" value wins over baseline "default"
  [[ "${content}" == *'"custom"'* ]]
  # existing "extra" key preserved
  [[ "${content}" == *'"extra"'* ]]

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline idempotent-no-rewrite" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  local original_root="${TERMINATOR_MODULE_ROOT_DIR}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.terminator/config/claude"
  printf '{"statusLine":{"type":"command"}}\n' \
    >"${temp_home}/.terminator/config/claude/settings.base.json"
  TERMINATOR_MODULE_ROOT_DIR="${temp_home}/.terminator"

  mkdir -p "${temp_home}/.claude"
  # Pre-populate with merged content (baseline already applied)
  jq -s '.[0] * .[1]' \
    "${temp_home}/.terminator/config/claude/settings.base.json" \
    <(printf '{"statusLine":{"type":"command"}}\n') \
    >"${temp_home}/.claude/settings.json"

  local mtime_before
  mtime_before="$(stat -c %Y "${temp_home}/.claude/settings.json" 2>/dev/null \
    || stat -f %m "${temp_home}/.claude/settings.json")"

  sleep 1

  run terminator::claude::settings::merge_baseline

  HOME="${original_home}"
  TERMINATOR_MODULE_ROOT_DIR="${original_root}"

  assert_success

  local mtime_after
  mtime_after="$(stat -c %Y "${temp_home}/.claude/settings.json" 2>/dev/null \
    || stat -f %m "${temp_home}/.claude/settings.json")"

  [[ "${mtime_before}" == "${mtime_after}" ]]

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline leaves-file-untouched-on-invalid-json" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  local original_root="${TERMINATOR_MODULE_ROOT_DIR}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.terminator/config/claude"
  printf '{"statusLine":{"type":"command","command":"default"}}\n' \
    >"${temp_home}/.terminator/config/claude/settings.base.json"
  TERMINATOR_MODULE_ROOT_DIR="${temp_home}/.terminator"

  mkdir -p "${temp_home}/.claude"
  # Truncated (invalid) JSON, as left behind by an interrupted writer
  local original_content='{"statusLine":{"type":"command","command":"custom"'
  printf '%s\n' "${original_content}" >"${temp_home}/.claude/settings.json"

  run terminator::claude::settings::merge_baseline

  HOME="${original_home}"
  TERMINATOR_MODULE_ROOT_DIR="${original_root}"

  assert_failure 1

  # invalid content is left byte-for-byte intact rather than clobbered
  local content
  content="$(cat "${temp_home}/.claude/settings.json")"
  [[ "${content}" == "${original_content}" ]]

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline seeds-empty-file-from-baseline" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  local original_root="${TERMINATOR_MODULE_ROOT_DIR}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.terminator/config/claude"
  printf '{"statusLine":{"type":"command","command":"default"}}\n' \
    >"${temp_home}/.terminator/config/claude/settings.base.json"
  TERMINATOR_MODULE_ROOT_DIR="${temp_home}/.terminator"

  mkdir -p "${temp_home}/.claude"
  printf '\n' >"${temp_home}/.claude/settings.json"

  run terminator::claude::settings::merge_baseline

  HOME="${original_home}"
  TERMINATOR_MODULE_ROOT_DIR="${original_root}"

  assert_success

  # empty file has nothing to preserve; baseline seeds it
  local content
  content="$(cat "${temp_home}/.claude/settings.json")"
  [[ "${content}" == *'"statusLine"'* ]]
  [[ "${content}" == *'"default"'* ]]

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::settings::merge_baseline
@test "terminator::claude::settings::merge_baseline respects-claude-config-dir" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local \
    temp_parent \
    original_config_dir="${CLAUDE_CONFIG_DIR}"
  temp_parent="$(mktemp -d)"
  # Not created up front, so the merge also has to create the directory.
  export CLAUDE_CONFIG_DIR="${temp_parent}/claude-config"

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  local original_root="${TERMINATOR_MODULE_ROOT_DIR}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.terminator/config/claude"
  printf '{"statusLine":{"type":"command"}}\n' \
    >"${temp_home}/.terminator/config/claude/settings.base.json"
  TERMINATOR_MODULE_ROOT_DIR="${temp_home}/.terminator"

  run terminator::claude::settings::merge_baseline

  HOME="${original_home}"
  TERMINATOR_MODULE_ROOT_DIR="${original_root}"
  if [[ -n "${original_config_dir}" ]]; then
    export CLAUDE_CONFIG_DIR="${original_config_dir}"
  else
    unset CLAUDE_CONFIG_DIR
  fi

  assert_success
  assert [ -f "${temp_parent}/claude-config/settings.json" ]
  refute [ -f "${temp_home}/.claude/settings.json" ]

  local content
  content="$(cat "${temp_parent}/claude-config/settings.json")"
  [[ "${content}" == *'"statusLine"'* ]]

  rm -rf "${temp_parent}" "${temp_home}"
}

################################################################################
# terminator::claude::plugin::marketplace::exists
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists when-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists when-not-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"name":"other-marketplace","source":"github","repo":"someone/other"}]\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists no-substring-match" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"name":"my-plugins-extended","source":"github","repo":"rbuchss/my-plugins-extended"}]\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists matches-ref-pinned-marketplace" {
  # A marketplace registered with a pinned ref still lists the bare repo, so a
  # ref-pinned registration must match its repo without the ref.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins","ref":"v3.1.2"}]\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_success
}

################################################################################
# terminator::claude::plugin::exists
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::exists
@test "terminator::claude::plugin::exists when-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"id":"greeter@my-plugins","version":"1.0.0"}]\n'
  }

  run terminator::claude::plugin::exists 'greeter@my-plugins'

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::exists
@test "terminator::claude::plugin::exists when-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"id":"other@other-marketplace","version":"1.0.0"}]\n'
  }

  run terminator::claude::plugin::exists 'greeter@my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::exists
@test "terminator::claude::plugin::exists no-substring-match" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"id":"greeter@my-plugins-extended","version":"1.0.0"}]\n'
  }

  run terminator::claude::plugin::exists 'greeter@my-plugins'

  assert_failure
}

################################################################################
# terminator::claude::plugin::is_enabled
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::is_enabled
@test "terminator::claude::plugin::is_enabled when-enabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":true}]\n'
  }

  run terminator::claude::plugin::is_enabled 'greeter@my-plugins'

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::is_enabled
@test "terminator::claude::plugin::is_enabled when-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":false}]\n'
  }

  run terminator::claude::plugin::is_enabled 'greeter@my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::is_enabled
@test "terminator::claude::plugin::is_enabled when-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo '[]'
  }

  run terminator::claude::plugin::is_enabled 'greeter@my-plugins'

  assert_failure
}

################################################################################
# terminator::claude::plugin::__settle_disabled__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::__settle_disabled__
@test "terminator::claude::plugin::__settle_disabled__ disables-when-enabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":true}]\n'
        ;;
      'plugin disable greeter@my-plugins')
        echo 'disable called'
        return 0
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::__settle_disabled__ greeter@my-plugins

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::__settle_disabled__
@test "terminator::claude::plugin::__settle_disabled__ noops-when-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":false}]\n'
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::__settle_disabled__ greeter@my-plugins

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::__settle_disabled__
@test "terminator::claude::plugin::__settle_disabled__ noops-when-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json') echo '[]' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::__settle_disabled__ greeter@my-plugins

  assert_success
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::plugin::register
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins

  assert_failure
  assert_output --partial 'greeter@my-plugins'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register when-missing-plugin-flag" {
  run terminator::claude::plugin::register --marketplace rbuchss/my-plugins

  assert_failure 1
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register when-missing-marketplace-flag" {
  run terminator::claude::plugin::register --plugin greeter@my-plugins

  assert_failure 1
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register when-already-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":true}]\n'
        ;;
    esac
  }

  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register installs-and-enables" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json')
        echo '[]'
        ;;
      plugin\ marketplace\ add\ *)
        return 0
        ;;
      'plugin list --json')
        echo '[]'
        ;;
      plugin\ install\ *)
        return 0
        ;;
      plugin\ enable\ *)
        return 0
        ;;
    esac
  }

  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins \
    --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register with-version-delegates-to-sync" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":true}]\n'
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  # Installed version matches the pin, so sync is a no-op (no marketplace or
  # install calls).
  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins \
    --version 1.0.0

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register without-version-delegates-to-install-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Simulate `claude plugin install` auto-enabling: the plugin is absent until
  # installed, then reported enabled. The disabled reconcile must disable it
  # after the install instead of leaving it enabled.
  __installed__=false

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json') echo '[]' ;;
      plugin\ marketplace\ add\ *) return 0 ;;
      'plugin list --json')
        if [[ "${__installed__}" == true ]]; then
          printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":true}]\n'
        else
          echo '[]'
        fi
        ;;
      plugin\ install\ *)
        __installed__=true
        return 0
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      plugin\ enable\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins \
    --disabled

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::register
@test "terminator::claude::plugin::register with-version-settles-disabled-without-reinstall" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # The installed version matches the pin, so only the disabled reconcile runs;
  # no marketplace, install, or enable calls.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"1.0.0","enabled":true}]\n'
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::register \
    --plugin greeter@my-plugins \
    --marketplace rbuchss/my-plugins \
    --version 1.0.0 \
    --disabled

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::mcp::__parse_options__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_options__
@test "terminator::claude::mcp::__parse_options__ defaults" {
  local force version

  terminator::claude::mcp::__parse_options__ force version

  [[ "${force}" == 0 ]]
  [[ -z "${version}" ]]
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_options__
@test "terminator::claude::mcp::__parse_options__ captures-force-and-version" {
  local force version

  terminator::claude::mcp::__parse_options__ force version --force --version 1.2.3

  [[ "${force}" == 1 ]]
  [[ "${version}" == 1.2.3 ]]
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__parse_options__
@test "terminator::claude::mcp::__parse_options__ when-unknown-option" {
  local force version

  run terminator::claude::mcp::__parse_options__ force version --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

################################################################################
# terminator::claude::mcp::__sync__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::__sync__
@test "terminator::claude::mcp::__sync__ skips-when-value-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  run terminator::claude::mcp::__sync__ foo 1.0.0 1.0.0 0 user -- cmd

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__sync__
@test "terminator::claude::mcp::__sync__ readds-when-value-differs" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 0; }

  run terminator::claude::mcp::__sync__ foo 1.0.0 2.0.0 0 user -- cmd

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__sync__
@test "terminator::claude::mcp::__sync__ readds-when-current-empty" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 0; }

  run terminator::claude::mcp::__sync__ foo '' 2.0.0 0 user -- cmd

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__sync__
@test "terminator::claude::mcp::__sync__ force-readds-when-value-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude { return 0; }

  run terminator::claude::mcp::__sync__ foo 1.0.0 1.0.0 1 user -- cmd

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::__sync__
@test "terminator::claude::mcp::__sync__ removes-and-adds-at-passed-scope" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'mcp remove --scope project foo') echo 'removed at project scope' ;;
      'mcp add --scope project foo -- cmd') echo 'added at project scope' ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  local \
    temp_repo \
    original_dir="${PWD}"
  temp_repo="$(mktemp -d)"
  git init -q "${temp_repo}"
  printf '{"mcpServers":{"foo":{"command":"echo","args":["hi"]}}}\n' \
    >"${temp_repo}/.mcp.json"
  cd "${temp_repo}"

  run terminator::claude::mcp::__sync__ foo 1.0.0 2.0.0 0 project -- cmd

  cd "${original_dir}"
  rm -rf "${temp_repo}"

  assert_success
  assert_output --partial 'removed at project scope'
  assert_output --partial 'added at project scope'
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::mcp::enable::* --version override
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 version-override-readds-on-mismatch" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@4.4.4"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::context7 --version 9.9.9

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::context7
@test "terminator::claude::mcp::enable::context7 version-override-skips-on-match" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo 'should not be called'
    return 1
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"context7":{"command":"bunx","args":["-y","@upstash/context7-mcp@9.9.9"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::context7 --version 9.9.9

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::enable::atlassian
@test "terminator::claude::mcp::enable::atlassian version-override-readds-on-mismatch" {
  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  local temp_home
  temp_home="$(mktemp -d)"
  printf '{"mcpServers":{"atlassian":{"command":"uvx","args":["mcp-atlassian==0.21.0"]}}}\n' \
    >"${temp_home}/.claude.json"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::mcp::enable::atlassian --version 0.99.0

  HOME="${original_home}"
  rm -rf "${temp_home}"

  assert_success
}

################################################################################
# terminator::claude::plugin::installed_version
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::installed_version
@test "terminator::claude::plugin::installed_version returns-version" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '[{"id":"greeter@my-plugins","version":"1.2.3","enabled":true}]\n'
  }

  run terminator::claude::plugin::installed_version greeter@my-plugins

  assert_success
  assert_output '1.2.3'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::installed_version
@test "terminator::claude::plugin::installed_version when-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude { echo '[]'; }

  run terminator::claude::plugin::installed_version greeter@my-plugins

  assert_success
  assert_output ''
}

################################################################################
# terminator::claude::plugin::installed_commit
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::installed_commit
@test "terminator::claude::plugin::installed_commit returns-sha" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.claude/plugins"
  printf '{"plugins":{"greeter@my-plugins":[{"gitCommitSha":"abc1234def"}]}}\n' \
    >"${temp_home}/.claude/plugins/installed_plugins.json"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::plugin::installed_commit greeter@my-plugins

  HOME="${original_home}"

  assert_success
  assert_output 'abc1234def'

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::plugin::installed_commit
@test "terminator::claude::plugin::installed_commit when-file-missing" {
  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  run terminator::claude::plugin::installed_commit greeter@my-plugins

  HOME="${original_home}"

  assert_success
  assert_output ''

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::plugin::installed_commit
@test "terminator::claude::plugin::installed_commit respects-claude-config-dir" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local \
    temp_config \
    original_config_dir="${CLAUDE_CONFIG_DIR}"
  temp_config="$(mktemp -d)"
  mkdir -p "${temp_config}/plugins"
  printf '{"plugins":{"greeter@my-plugins":[{"gitCommitSha":"abc1234def"}]}}\n' \
    >"${temp_config}/plugins/installed_plugins.json"
  export CLAUDE_CONFIG_DIR="${temp_config}"

  run terminator::claude::plugin::installed_commit greeter@my-plugins

  if [[ -n "${original_config_dir}" ]]; then
    export CLAUDE_CONFIG_DIR="${original_config_dir}"
  else
    unset CLAUDE_CONFIG_DIR
  fi

  assert_success
  assert_output 'abc1234def'

  rm -rf "${temp_config}"
}

################################################################################
# terminator::claude::plugin::sync
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync semver-skips-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"2.5.1","enabled":true}]\n'
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins 2.5.1 0

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync semver-updates-when-version-differs" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"2.4.0","enabled":true}]\n'
        ;;
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins 2.5.1 0

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync sha-skips-when-commit-matches" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.claude/plugins"
  printf '{"plugins":{"greeter@my-plugins":[{"gitCommitSha":"4913d94c903fbd1193cc6073d9331d28060f4156"}]}}\n' \
    >"${temp_home}/.claude/plugins/installed_plugins.json"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo "should not be called: $*"
    return 1
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins 4913d94 0

  HOME="${original_home}"

  assert_success

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync sha-reinstalls-when-commit-differs" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.claude/plugins"
  printf '{"plugins":{"greeter@my-plugins":[{"gitCommitSha":"deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"}]}}\n' \
    >"${temp_home}/.claude/plugins/installed_plugins.json"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins 4913d94 0

  HOME="${original_home}"

  assert_success

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync tag-skips-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # A v-prefixed tag resolves to the plugin.json version without the leading v.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins v3.1.2 0

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync tag-reinstalls-when-version-differs" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"2.5.1","enabled":true}]\n'
        ;;
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins v3.1.2 0

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync tag-force-reinstalls-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        ;;
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins v3.1.2 1

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync semver-settles-disabled-on-version-match" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Version matches but the plugin is enabled: disable it without a reinstall.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"2.5.1","enabled":true}]\n'
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins 2.5.1 0 1

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync sha-settles-disabled-on-commit-match" {
  command -v jq >/dev/null 2>&1 || skip 'jq not available'

  local temp_home
  temp_home="$(mktemp -d)"
  local original_home="${HOME}"
  HOME="${temp_home}"

  mkdir -p "${temp_home}/.claude/plugins"
  printf '{"plugins":{"greeter@my-plugins":[{"gitCommitSha":"4913d94c903fbd1193cc6073d9331d28060f4156"}]}}\n' \
    >"${temp_home}/.claude/plugins/installed_plugins.json"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Commit matches but the plugin is enabled: disable it without a reinstall.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"2.5.1","enabled":true}]\n'
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins 4913d94 0 1

  HOME="${original_home}"

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'

  rm -rf "${temp_home}"
}

# bats test_tags=terminator::claude,terminator::claude::plugin::sync
@test "terminator::claude::plugin::sync tag-settles-disabled-on-version-match" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Version matches but the plugin is enabled: disable it without a reinstall.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::sync \
    greeter@my-plugins rbuchss/my-plugins v3.1.2 0 1

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::plugin::__pin_and_reinstall__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::__pin_and_reinstall__
@test "terminator::claude::plugin::__pin_and_reinstall__ removes-existing-then-reinstalls" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::__pin_and_reinstall__ \
    rbuchss/my-plugins v3.1.2 greeter@my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::__pin_and_reinstall__
@test "terminator::claude::plugin::__pin_and_reinstall__ adds-when-marketplace-absent" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json') echo '[]' ;;
      plugin\ marketplace\ remove\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::__pin_and_reinstall__ \
    rbuchss/my-plugins v3.1.2 greeter@my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::__pin_and_reinstall__
@test "terminator::claude::plugin::__pin_and_reinstall__ skips-enable-when-already-enabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # `claude plugin install` enables the plugin, so the follow-up enable must be
  # skipped rather than erroring with "already enabled".
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        ;;
      plugin\ enable\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::__pin_and_reinstall__ \
    rbuchss/my-plugins v3.1.2 greeter@my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::__pin_and_reinstall__
@test "terminator::claude::plugin::__pin_and_reinstall__ disables-instead-of-enables" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # `claude plugin install` enables by default, so the reconcile must disable
  # after reinstalling rather than enabling.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin marketplace list --json')
        printf '[{"name":"my-plugins","source":"github","repo":"rbuchss/my-plugins"}]\n'
        ;;
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        ;;
      plugin\ enable\ *)
        echo 'should not be called'
        return 1
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::__pin_and_reinstall__ \
    rbuchss/my-plugins v3.1.2 greeter@my-plugins 1

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

################################################################################
# terminator::claude::plugin::install
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::install
@test "terminator::claude::plugin::install skips-redundant-enable-after-fresh-install" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Simulate `claude plugin install` auto-enabling: plugin is absent and
  # disabled until installed, then reported enabled. The follow-up enable must
  # be skipped rather than erroring with "already enabled".
  __installed__=false

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        if [[ "${__installed__}" == true ]]; then
          printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        else
          echo '[]'
        fi
        ;;
      plugin\ install\ *)
        __installed__=true
        return 0
        ;;
      plugin\ enable\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::install greeter@my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::install
@test "terminator::claude::plugin::install enables-when-installed-but-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Plugin is installed but disabled: enable must be called.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":false}]\n'
        ;;
      plugin\ enable\ *) return 0 ;;
      plugin\ install\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::install greeter@my-plugins

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::install
@test "terminator::claude::plugin::install installs-then-disables-when-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Simulate `claude plugin install` auto-enabling: the plugin is absent until
  # installed, then reported enabled. The disabled reconcile must disable it
  # after the install.
  __installed__=false

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        if [[ "${__installed__}" == true ]]; then
          printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        else
          echo '[]'
        fi
        ;;
      plugin\ install\ *)
        __installed__=true
        return 0
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      plugin\ enable\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::install greeter@my-plugins 1

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::install
@test "terminator::claude::plugin::install disables-when-installed-and-enabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Installed and enabled: skip the install and just disable.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":true}]\n'
        ;;
      plugin\ disable\ *)
        echo 'disable called'
        return 0
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::install greeter@my-plugins 1

  assert_success
  assert_output --partial 'disable called'
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::install
@test "terminator::claude::plugin::install noops-when-installed-and-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Installed and already disabled: nothing to do.
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":false}]\n'
        ;;
      *)
        echo "should not be called: $*"
        return 1
        ;;
    esac
  }

  run terminator::claude::plugin::install greeter@my-plugins 1

  assert_success
  refute_output --partial 'should not be called'
}

# bats test_tags=terminator::claude,terminator::claude::plugin::install
@test "terminator::claude::plugin::install skips-redundant-disable-when-install-leaves-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  # Simulate `claude plugin install` leaving the plugin disabled: the
  # follow-up disable must be skipped rather than erroring.
  __installed__=false

  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$*" in
      'plugin list --json')
        if [[ "${__installed__}" == true ]]; then
          printf '[{"id":"greeter@my-plugins","version":"3.1.2","enabled":false}]\n'
        else
          echo '[]'
        fi
        ;;
      plugin\ install\ *)
        __installed__=true
        return 0
        ;;
      plugin\ disable\ *)
        echo 'should not be called'
        return 1
        ;;
      plugin\ enable\ *)
        echo 'should not be called'
        return 1
        ;;
      *) return 0 ;;
    esac
  }

  run terminator::claude::plugin::install greeter@my-plugins 1

  assert_success
  refute_output --partial 'should not be called'
}
