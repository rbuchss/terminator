---
globs: ["*.sh", "*.bash", "*.bats"]
---

# Bash Style Guidelines

- Use double quotes and braces for variable expansion: `"${variable}"` not `"$variable"`
- Exception: Positional parameters like `$1`, `$2`, `$*`, `$@`, `$#` are fine without braces
- Exception: Special variables like `$?` (exit status) don't need braces
- Always quote to prevent word splitting: `"${var}"` not `${var}`

Examples:
- Good: `"${PROJECT_NAME}"`, `"${HOME}"`, `"$1"`, `"$2"`, `"$?"`
- Bad: `"$PROJECT_NAME"`, `$HOME`, `"${1}"`

## Multi-variable `local` declarations

When declaring more than one local variable, put `local` on its own line and
place each variable on its own indented continuation line. Single-variable
declarations stay on one line.

```bash
# Good: single variable on one line
local module="$1"

# Good: multiple variables, each on its own continuation line
local \
  module="$1" \
  should_source_status=0 \
  should_not_source_status=1

# Bad: first variable crowded onto the `local` line
local module="$1" \
  should_source_status=0 \
  should_not_source_status=1
```

## Arithmetic comparisons

Prefer `(( ))` for arithmetic over `[[ ]]` with `-eq`, `-ne`, `-gt`, etc.:

```bash
# Good
(( ${#array[@]} == 0 ))
(( count > 5 ))

# Bad
[[ ${#array[@]} -eq 0 ]]
[[ "${count}" -gt 5 ]]
```

## `printf -v` and local variable scoping

When a function uses `printf -v "$1"` to write to a caller-provided variable name,
the function's own `local` variables shadow the caller's. If both use the same name,
`printf -v` writes to the local copy, and the caller never sees the result.

Use `__` prefixed names **only** for the two locals that actually risk collision:
the captured output-variable name (e.g. `local __output_var__="$1"`) and the local
that holds the value written via `printf -v` (e.g. the `__result__` in
`printf -v "${__output_var__}" '%s' "${__result__}"`). Other locals in the same
function, such as bookkeeping flags, loop indices, and argument arrays, should
stay plain. Callers do not pass those names as output-variable arguments in
practice, and blanket-prefixing adds noise. Regular functions that do not use
`printf -v` should use plain local variable names. Do not cargo-cult the prefix
into every function.

```bash
# Bad: caller passes "cmd" as $1, but local cmd shadows it
my_func() {
  local cmd="some_value"
  printf -v "$1" '%s' "${cmd}"  # writes to local cmd, not caller's
}

# Good: prefixed internal name avoids collision with printf -v
my_func() {
  local __my_func_cmd__="some_value"
  printf -v "$1" '%s' "${__my_func_cmd__}"
}

# Bad: no printf -v, so __ prefix is unnecessary noise
parse_args() {
  local __force__=false
}

# Good: plain names when printf -v is not involved
parse_args() {
  local force=false
}
```
