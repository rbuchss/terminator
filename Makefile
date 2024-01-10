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

TEST_COMMAND := ./test/bats/bats-core/bin/bats --pretty --recursive $(TEST_DIRS)

.PHONY: guards
guards: test lint

.PHONY: test
test:
	kcov \
		--clean \
		--include-path=./terminator/src/,./tmux/src/ \
		--include-pattern=.sh \
		--exclude-pattern=/test/,/coverage/,/report/ \
		--bash-method=DEBUG \
		--bash-parser=/bin/bash \
		--bash-parse-files-in-dir=. \
		--configure=command-name="$(TEST_COMMAND)" \
		coverage \
		$(TEST_COMMAND)

.PHONY: lint
lint:
	shellcheck $$(git ls-files -- . $(GIT_IGNORE))
