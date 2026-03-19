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

Use `__` prefixed names for internal variables in functions that accept output variable names:

```bash
# Bad: caller passes "cmd" as $1, but local cmd shadows it
my_func() {
  local cmd="some_value"
  printf -v "$1" '%s' "${cmd}"  # writes to local cmd, not caller's
}

# Good: prefixed internal name avoids collision
my_func() {
  local __my_func_cmd__="some_value"
  printf -v "$1" '%s' "${__my_func_cmd__}"
}
```
