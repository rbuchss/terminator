# terminator

Tis my bash dot-profile.

A modular Bash shell utility framework managed as a dotfiles repository via [homesick](https://github.com/technicalpickles/homesick) or [homeshick](https://github.com/andsens/homeshick).

## Installation

```bash
# Using homesick
homesick clone https://github.com/rbuchss/terminator.git
homesick link terminator

# Or using homeshick
homeshick clone https://github.com/rbuchss/terminator.git
homeshick link terminator
```

## Dependencies

- **Docker** - required for running tests, linting, and formatting
- **Powerline fonts** - required for prompt symbols

Dev tooling (shellcheck, shfmt, bats, kcov) runs inside Docker. No local install needed.

## Project Structure

```
terminator/src/    # Bash source modules (one module per file)
terminator/config/ # Shell and tool configuration files
terminator/bin/    # Standalone scripts and utilities
terminator/tools/  # Development tooling (function export generator)
test/              # BATS test files (mirrors src/ structure)
vendor/            # Git submodules and vendored scripts
vendor/test/bats/  # BATS test framework (bats-core fork, bats-assert, bats-support)
```

## Development Commands

All `compose-*` targets run inside Docker via `docker compose`. This is the standard way to run checks locally.

### Primary Workflow

```bash
make                    # Runs compose-guards (default target)
make compose-guards     # Run all checks: test + coverage, lint, format check, function exports check
```

### Testing

```bash
make compose-test       # Run tests with kcov coverage
make compose-test-quick # Run tests without coverage (faster)
```

**Targeted tests** - use `TEST_PATH` and `FILTER_TAGS` overrides (comma-delimited):

```bash
make compose-test TEST_PATH=test/logger.bats
make compose-test TEST_PATH=test/logger.bats,test/string.bats
make compose-test FILTER_TAGS=terminator::logger
make compose-test FILTER_TAGS=terminator::logger,terminator::string
```

### Linting

```bash
make compose-lint       # Run shellcheck on all source and test files
```

### Formatting

```bash
make compose-format-check  # Check formatting (no changes)
make compose-format        # Auto-format with shfmt
```

### Function Exports

These targets run locally (no `compose-` wrapper), but `function-exports-check` also runs in Docker as part of `compose-guards`.

```bash
make function-exports-check  # Check for missing function exports (CI-safe)
make function-exports        # Check and interactively add missing exports
```

### Debug Shell

```bash
make compose-debug     # Open an interactive bash shell in the Docker container
```

## Module System

Each source file uses the module system for load-once guards and lifecycle management:

```bash
#!/bin/bash
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

terminator::__module__::load || return 0

function terminator::mymodule::__enable__ {
  alias my-alias='terminator::mymodule::my_function'
}

function terminator::mymodule::__disable__ {
  unalias my-alias
}

# ... function definitions ...

function terminator::mymodule::__export__ {
  export -f terminator::mymodule::my_function
}

function terminator::mymodule::__recall__ {
  export -fn terminator::mymodule::my_function
}
```

- `terminator::__module__::load || return 0` - source guard, prevents loading a module twice
- `__enable__` - sets up aliases and other shell state
- `__disable__` - tears down aliases and shell state (inverse of `__enable__`)
- `__export__` - makes functions available to subshells via `export -f`
- `__recall__` - removes function exports via `export -fn` (inverse of `__export__`)

## File Categorization

`.gitattributes` assigns `category` and `language` attributes to files. The lint and format targets select files via `git ls-files` pathspec queries against these attributes (e.g. `:(top,attr:category=source language=bash)`).

Standard `.sh` and `.bats` extensions are matched automatically. Extensionless scripts (e.g. `terminator/bin/tmux-help`) need an explicit entry:

```gitattributes
terminator/bin/my-script      language=bash
```

## Adding a New Module

1. Create the source file at `terminator/src/{name}.sh` using the [module boilerplate](#module-system) above.

2. Register the module in `terminator/config/__modules__.sh`. Add the source path to the `terminator::source` call and the module name to the `__modules__` array.

3. Create the test file at `test/{name}.bats`:

    ```bash
    #!/usr/bin/env bats
    load test_helper
    setup_with_coverage 'terminator/src/{name}.sh'
    bats_require_minimum_version 1.5.0

    # bats test_tags=terminator::{name}
    @test "terminator::{name}::my_function" {
      run terminator::{name}::my_function
      assert_success
    }
    ```

4. If adding extensionless scripts, update `.gitattributes` (see [File Categorization](#file-categorization)).

5. Run `make function-exports` to detect and add any missing exports.

6. Run `make` to validate everything (tests, lint, format, exports).

## Testing

Tests use a [BATS fork](https://github.com/rbuchss/bats-core) with coverage tracing support (vendored as git submodules). Coverage is collected via [kcov](https://github.com/SimonKagstrom/kcov) when available.

A convenience shim at `bin/bats` wraps the vendored BATS binary with project defaults (`--setup-suite-file`, `--recursive`, `--pretty`). Run it directly for quick local test runs without Docker:

```bash
bin/bats                    # Run full test suite
bin/bats test/logger.bats   # Run a specific test file
```

The Docker test image is based on Alpine/BusyBox and uses a custom builder image (`rbuchss/terminator-tester-builder`) with all tooling pre-installed.

Coverage reports are generated automatically during `make compose-test` runs.

## CI/CD

All CI checks run inside the same Docker image as the local `compose-*` targets via a custom GitHub Action (`.github/actions/run-make`), ensuring parity between local and CI environments.

### Pull Request Checks

Every pull request to `main` runs four checks:

- **Test** - `make test` with kcov coverage (posts coverage report as PR comment)
- **Lint** - `make lint` (shellcheck)
- **Format check** - `make format-check` (shfmt)
- **Function exports check** - `make function-exports-check`

### Manual Runs

The `workflow_dispatch` workflow (`main.yml`) lets you run any target manually from the GitHub Actions UI: `test`, `lint`, `format-check`, `function-exports-check`, or `guards`.

## License

[MIT](LICENSE)
