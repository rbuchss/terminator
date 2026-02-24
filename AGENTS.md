# Terminator - AI Agent Project Instructions

See [README.md](README.md) for project structure, development commands, the module system, and the [Adding a New Module](README.md#adding-a-new-module) workflow.

## Quick Reference

- `make` - runs all checks (default target: `compose-guards`)
- `make compose-test TEST_PATH=test/foo.bats FILTER_TAGS=terminator::foo` - targeted tests
- All `compose-*` targets run in Docker. Tests, lint, and format **must** run via Docker (Alpine/BusyBox environment).

## Output Variable Pattern

Many functions accept an optional output variable name. Instead of capturing stdout, callers pass a variable name and the function writes to it via `printf -v`:

```bash
terminator::string::bytes_to_length_offset --value "hello" result_var
```

## Running Tests from AI Agents

The `compose-*` targets use `docker compose run` and work in non-interactive contexts like AI agent shells. Run them directly:

```bash
make compose-guards
make compose-test TEST_PATH=test/foo.bats FILTER_TAGS=terminator::foo
```

For interactive debugging, use `make compose-debug` which keeps the TTY for a live shell.

## Known Limitations

Tests run in a Docker Alpine/BusyBox environment. Some kcov coverage edge cases exist with BATS `setup`/`teardown` functions and dynamically sourced files.
