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
