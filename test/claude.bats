#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/claude.sh'

bats_require_minimum_version 1.5.0

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
