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

################################################################################
# terminator::claude::__disable__
################################################################################

# bats test_tags=terminator::claude,terminator::claude::__disable__
@test "terminator::claude::__disable__ runs-without-error" {
  run terminator::claude::__disable__

  assert_success
}

################################################################################
# terminator::claude
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::add::context7
@test "terminator::claude::mcp::add::context7 function-exists" {
  run type -t terminator::claude::mcp::add::context7

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::context7
@test "terminator::claude::mcp::add::context7 when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::add::context7

  assert_failure
  assert_output --partial 'context7'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::context7
@test "terminator::claude::mcp::add::context7 when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::mcp::add::context7 --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::context7
@test "terminator::claude::mcp::add::context7 skips-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          list) echo 'context7: bunx -y @upstash/context7-mcp@2.1.2' ;;
          remove)
            echo 'should not be called'
            return 1
            ;;
          add)
            echo 'should not be called'
            return 1
            ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::context7

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::context7
@test "terminator::claude::mcp::add::context7 force-readds-when-version-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          list) echo 'context7: bunx -y @upstash/context7-mcp@2.1.2' ;;
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::context7 --force

  assert_success
}

################################################################################
# terminator::claude::mcp::add::serena
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::add::serena
@test "terminator::claude::mcp::add::serena when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::add::serena

  assert_failure
  assert_output --partial 'serena'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::serena
@test "terminator::claude::mcp::add::serena when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::claude::mcp::add::serena --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::serena
@test "terminator::claude::mcp::add::serena skips-when-commit-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          list) echo 'serena: uvx --from git+https://github.com/oraios/serena@2ab807a1ff13ffc08e82070e44c3d2bfc5aa75f8' ;;
          remove)
            echo 'should not be called'
            return 1
            ;;
          add)
            echo 'should not be called'
            return 1
            ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::serena

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::serena
@test "terminator::claude::mcp::add::serena force-readds-when-commit-matches" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    case "$1" in
      mcp)
        shift
        case "$1" in
          list) echo 'serena: uvx --from git+https://github.com/oraios/serena@2ab807a1ff13ffc08e82070e44c3d2bfc5aa75f8' ;;
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::serena --force

  assert_success
}

################################################################################
# terminator::claude::mcp::add::atlassian
################################################################################

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian function-exists" {
  run type -t terminator::claude::mcp::add::atlassian

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian when-claude-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::claude::mcp::add::atlassian

  assert_failure
  assert_output --partial 'mcp-atlassian'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian when-all-env-vars-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  unset JIRA_URL JIRA_USERNAME JIRA_API_TOKEN \
    CONFLUENCE_URL CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN

  run terminator::claude::mcp::add::atlassian

  assert_failure
  assert_output --partial 'missing env vars'
  assert_output --partial 'JIRA_URL'
  assert_output --partial 'CONFLUENCE_API_TOKEN'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian when-partial-env-vars-missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  unset CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN

  run terminator::claude::mcp::add::atlassian

  assert_failure
  assert_output --partial 'missing env vars'
  assert_output --partial 'CONFLUENCE_USERNAME'
  assert_output --partial 'CONFLUENCE_API_TOKEN'
  refute_output --partial 'JIRA_URL'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian when-unknown-option" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  export JIRA_URL='https://hill-valley.atlassian.net'
  export JIRA_USERNAME='doc.brown@hill-valley.net'
  export JIRA_API_TOKEN='1.21-gigawatts'
  export CONFLUENCE_URL='https://hill-valley.atlassian.net/wiki'
  export CONFLUENCE_USERNAME='doc.brown@hill-valley.net'
  export CONFLUENCE_API_TOKEN='great-scott'

  run terminator::claude::mcp::add::atlassian --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian adds-when-not-installed" {
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
          list) echo '' ;;
          remove) return 0 ;;
          add) __add_called__=true ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::atlassian

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian skips-when-version-matches" {
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
          list) echo 'atlassian: uvx mcp-atlassian==0.21.0' ;;
          remove)
            echo 'should not be called'
            return 1
            ;;
          add)
            echo 'should not be called'
            return 1
            ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::atlassian

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian force-readds-when-version-matches" {
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
          list) echo 'atlassian: uvx mcp-atlassian==0.21.0' ;;
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::atlassian --force

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::mcp::add::atlassian
@test "terminator::claude::mcp::add::atlassian updates-when-version-mismatches" {
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
          list) echo 'atlassian: uvx mcp-atlassian==0.19.0' ;;
          remove) return 0 ;;
          add) return 0 ;;
        esac
        ;;
    esac
  }

  run terminator::claude::mcp::add::atlassian

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
    printf '  ❯ my-plugins\n    Source: GitHub (rbuchss/my-plugins)\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists when-not-registered" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '  ❯ other-marketplace\n    Source: GitHub (someone/other)\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::marketplace::exists
@test "terminator::claude::plugin::marketplace::exists no-substring-match" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '  ❯ my-plugins-extended\n    Source: GitHub (rbuchss/my-plugins-extended)\n'
  }

  run terminator::claude::plugin::marketplace::exists 'rbuchss/my-plugins'

  assert_failure
}

################################################################################
# terminator::claude::plugin::exists
################################################################################

# bats test_tags=terminator::claude,terminator::claude::plugin::exists
@test "terminator::claude::plugin::exists when-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '  ❯ greeter@my-plugins\n    Version: 1.0.0\n'
  }

  run terminator::claude::plugin::exists 'greeter@my-plugins'

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::exists
@test "terminator::claude::plugin::exists when-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '  ❯ other@other-marketplace\n    Version: 1.0.0\n'
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
    printf '  ❯ greeter@my-plugins\n    Version: 1.0.0\n    Scope: user\n    Status: ✔ enabled\n'
  }

  run terminator::claude::plugin::is_enabled 'greeter@my-plugins'

  assert_success
}

# bats test_tags=terminator::claude,terminator::claude::plugin::is_enabled
@test "terminator::claude::plugin::is_enabled when-disabled" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    printf '  ❯ greeter@my-plugins\n    Version: 1.0.0\n    Scope: user\n    Status: ✘ disabled\n'
  }

  run terminator::claude::plugin::is_enabled 'greeter@my-plugins'

  assert_failure
}

# bats test_tags=terminator::claude,terminator::claude::plugin::is_enabled
@test "terminator::claude::plugin::is_enabled when-not-installed" {
  # shellcheck disable=SC2317 # invoked indirectly
  function claude {
    echo ''
  }

  run terminator::claude::plugin::is_enabled 'greeter@my-plugins'

  assert_failure
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
      'plugin marketplace list')
        printf '  ❯ my-plugins\n    Source: GitHub (rbuchss/my-plugins)\n'
        ;;
      'plugin list')
        printf '  ❯ greeter@my-plugins\n    Version: 1.0.0\n    Scope: user\n    Status: ✔ enabled\n'
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
      'plugin marketplace list')
        echo ''
        ;;
      plugin\ marketplace\ add\ *)
        return 0
        ;;
      'plugin list')
        echo ''
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
