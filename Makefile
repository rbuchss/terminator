TEST_DIRS := terminator/test/ tmux/test/

LINT_IGNORE := \
  *.bats \
  *.conf \
  *.md \
  Makefile \
  terminator/bin/dotfile-info \
  terminator/bin/uppercut \
  terminator/tools/grc/* \
  terminator/tools/ruby/* \
  home/* \
  test/fixtures/* \
  vendor/*

GIT_IGNORE := $(addsuffix ',$(addprefix ':!:,$(LINT_IGNORE)))

.PHONY: guards
guards: test lint

.PHONY: test
test:
	bats --pretty --recursive $(TEST_DIRS)

.PHONY: lint
lint:
	shellcheck $$(git ls-files -- . $(GIT_IGNORE))
