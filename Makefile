.PHONY: guards
guards: test linter

.PHONY: test
test:
	bats --pretty --recursive terminator/test/ tmux/test/

.PHONY: linter
linter:
	shellcheck $$(git ls-files -- . ':!:Makefile' ':!:*.md' ':!:*.bats' ':!:test/fixtures/*' ':!:*.conf' ':!:home/*' ':!:ruby_friends/*' ':!:grc/*' ':!:vendor/*')
