.PHONY: guards
guards: linter test

.PHONY: test
test:
	bats --pretty --recursive terminator/test/ tmux/test/

.PHONY: linter
linter:
	shellcheck $$(git ls-files -- . ':!:Makefile' ':!:*.md' ':!:*.bats' ":!:test/fixtures/*")
