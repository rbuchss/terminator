TEST_DIRS := terminator/test/ tmux/test/

LINTED_SOURCE_FILES := \
  ':(top,attr:category=source language=bash)'

LINTED_TEST_FILES := \
  ':(top,attr:category=test language=bash)' \
  ':(top,attr:category=test language=bats)'

LINTED_FILES := $(LINTED_SOURCE_FILES) $(LINTED_TEST_FILES)

TEST_COMMAND := ./vendor/test/bats/bats-core/bin/bats \
  --setup-suite-file ./test/test_suite.bash \
  --pretty \
  --recursive \
  $(TEST_DIRS)

.PHONY: guards
guards: test lint

.PHONY: test
test:
	kcov \
		--clean \
		--include-path=./terminator/src/,./tmux/src/ \
		--include-pattern=.sh \
		--exclude-pattern=/test/,/coverage/,/report/ \
		--path-strip-level=1 \
		--bash-method=DEBUG \
		--bash-parser=/bin/bash \
		--bash-parse-files-in-dir=. \
		--configure=command-name="$(TEST_COMMAND)" \
		coverage \
		$(TEST_COMMAND)

.PHONY: lint
lint:
	shellcheck $$(git ls-files -- $(LINTED_FILES))

.PHONY: linted-files
linted-files:
	git ls-files -- $(LINTED_FILES)

.PHONY: linted-source-files
linted-source-files:
	git ls-files -- $(LINTED_SOURCE_FILES)

.PHONY: linted-test-files
linted-test-files:
	git ls-files -- $(LINTED_TEST_FILES)
