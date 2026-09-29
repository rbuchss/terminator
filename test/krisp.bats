#!/usr/bin/env bats

# `stderr` is set by `run --separate-stderr` in tests below.
# shellcheck disable=SC2154

load test_helper

setup_with_coverage 'terminator/src/krisp.sh'

bats_require_minimum_version 1.5.0

################################################################################
# Fixtures
################################################################################

# Three meetings, newest first: Design review (ready), Weekly sync (ready),
# Retro (still processing).
KRISP_LIST_JSON='{"meetings":[{"id":"99887766554433221100ffeeddccbbaa","title":"Design review","started_at":"2026-07-11T14:00:00Z","duration":1800,"status":"ready"},{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"},{"id":"5566778899aabbccddeeff0011223344","title":"Retro","started_at":"2026-07-09T16:00:00Z","duration":900,"status":"processing"}],"next_cursor":null,"total":3}'

KRISP_EMPTY_LIST_JSON='{"meetings":[],"next_cursor":null,"total":0}'

# Pagination fixtures: page 1 returns the newest meeting plus a cursor, page 2
# is requested with that cursor and returns the next meeting.
KRISP_PAGE1_JSON='{"meetings":[{"id":"99887766554433221100ffeeddccbbaa","title":"Design review","started_at":"2026-07-11T14:00:00Z","duration":1800,"status":"ready"}],"next_cursor":"page2","total":1}'
KRISP_PAGE2_JSON='{"meetings":[{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"}],"next_cursor":null,"total":1}'

# Weekly sync detail (the second-newest meeting). Speaker 1 has a full name,
# speaker 2 only an email, speaker 3 is absent from the speakers map, and the
# last segment rolls the timestamp past an hour.
KRISP_MEETING_JSON='{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready","transcript":{"language":"en","speakers":{"1":{"email":"casey@example.com","first_name":"Casey","last_name":"Rivera"},"2":{"email":"sam@example.com"}},"segments":[{"speaker":1,"text":"lets get started","start":5,"end":9},{"speaker":2,"text":"sounds good","start":11,"end":13},{"speaker":3,"text":"unidentified voice","start":60,"end":62},{"speaker":1,"text":"wrapping up","start":3725,"end":3730}]}}'

# Design review detail (the newest meeting), for the no-arg path.
KRISP_MEETING2_JSON='{"id":"99887766554433221100ffeeddccbbaa","title":"Design review","started_at":"2026-07-11T14:00:00Z","duration":1800,"status":"ready","transcript":{"language":"en","speakers":{"1":{"email":"dana@example.com","first_name":"Dana","last_name":"Ng"}},"segments":[{"speaker":1,"text":"walking through the mockups","start":3,"end":7}]}}'

# A 200 response whose transcript has no segments.
KRISP_EMPTY_TRANSCRIPT_JSON='{"id":"99887766554433221100ffeeddccbbaa","title":"Design review","status":"ready","transcript":{"language":"en","speakers":{},"segments":[]}}'

KRISP_409_JSON='{"error":"This meeting is still processing. Transcript and notes are not available yet."}'

# Lexical cache entry names for the two ready meetings.
KRISP_MEETING_MD='2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__Weekly-sync.md'
KRISP_MEETING2_MD='2026-07-11T14-00-00Z__99887766554433221100ffeeddccbbaa__Design-review.md'

################################################################################
# Helpers
################################################################################

_krisp_env() {
  KRISP_API_KEY='test-key-12345'
  TERMINATOR_KRISP_CACHE_DIR="$(mktemp -d)"

  # The test image ships no curl, so the real dependency guard would fail.
  # Guard behavior is covered by dedicated tests; here every guard passes and
  # per-test curl mocks provide the network.
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }
}

# Seeds a cached transcript: renders BODY into its lexical markdown entry,
# optionally with comma-joined TAGS in the frontmatter.
# Usage: _seed_cache BODY [TAGS]
_seed_cache() {
  local filename
  terminator::krisp::__cache_filename__ "$1" filename
  mkdir -p "${TERMINATOR_KRISP_CACHE_DIR}"
  if [[ -n "${2:-}" ]]; then
    local rendered
    terminator::krisp::__render_markdown__ "$1" rendered "$2"
    printf '%s\n' "${rendered}" >"${TERMINATOR_KRISP_CACHE_DIR}/${filename}"
  else
    terminator::krisp::__render_markdown__ "$1" >"${TERMINATOR_KRISP_CACHE_DIR}/${filename}"
  fi
}

# Mocks a successful API: the meetings list and per-id meeting details, so a
# wrong meeting selection cannot hide behind a shared body.
_krisp_curl_ok() {
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_LIST_JSON}" '200'
        ;;
      *'/meetings/aabbccddeeff00112233445566778899'*)
        printf '%s\n%s\n' "${KRISP_MEETING_JSON}" '200'
        ;;
      *'/meetings/99887766554433221100ffeeddccbbaa'*)
        printf '%s\n%s\n' "${KRISP_MEETING2_JSON}" '200'
        ;;
    esac
  }
}

################################################################################
# terminator::krisp::__require_api_key__ / __require_curl__ / __require_jq__
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::require_api_key
@test "__require_api_key__ fails with a hint when KRISP_API_KEY is unset" {
  unset KRISP_API_KEY

  run terminator::krisp::__require_api_key__

  assert_failure
  assert_output --partial 'KRISP_API_KEY is not set'
}

# bats test_tags=terminator::krisp,terminator::krisp::require_api_key
@test "__require_api_key__ passes when KRISP_API_KEY is set" {
  KRISP_API_KEY='test-key-12345'

  run terminator::krisp::__require_api_key__

  assert_success
}

# bats test_tags=terminator::krisp,terminator::krisp::require_curl
@test "__require_curl__ fails when curl is missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::krisp::__require_curl__

  assert_failure
  assert_output --partial 'curl is required'
}

# bats test_tags=terminator::krisp,terminator::krisp::require_jq
@test "__require_jq__ fails when jq is missing" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::krisp::__require_jq__

  assert_failure
  assert_output --partial 'jq is required'
}

# bats test_tags=terminator::krisp,terminator::krisp::require_curl
@test "__require_curl__ passes when curl exists" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::krisp::__require_curl__

  assert_success
}

################################################################################
# Guard behavior at command level
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list requires KRISP_API_KEY" {
  unset KRISP_API_KEY

  run terminator::krisp::list

  assert_failure
  assert_output --partial 'KRISP_API_KEY is not set'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list -h shows usage without the key" {
  unset KRISP_API_KEY

  run terminator::krisp::list -h

  assert_success
  assert_output --partial 'Usage: krisp-list'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list rejects unknown options" {
  _krisp_env

  run terminator::krisp::list --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "krisp-list rejects the color flags" {
  _krisp_env

  run terminator::krisp::list --color

  assert_failure
  assert_output --partial 'unknown option'

  run terminator::krisp::list --no-color

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects unknown options" {
  _krisp_env

  run terminator::krisp::get --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "krisp-get rejects the color flags" {
  _krisp_env

  run terminator::krisp::get --color

  assert_failure
  assert_output --partial 'unknown option'

  run terminator::krisp::get --no-color

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache rejects unknown options" {
  run terminator::krisp::cache --bogus

  assert_failure
  assert_output --partial 'unknown option'

  # --add-tag moved to krisp-tag, so the old flag is unknown now.
  run terminator::krisp::cache --add-tag work --id aabbccdd

  assert_failure
  assert_output --partial "krisp-cache unknown option: '--add-tag'"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache rejects positional arguments" {
  run terminator::krisp::cache foo

  assert_failure
  assert_output --partial "krisp-cache unexpected argument: 'foo'"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --color and --no-color are mutually exclusive" {
  run terminator::krisp::cache --color --no-color

  assert_failure
  assert_output --partial '--color and --no-color are mutually exclusive'

  run terminator::krisp::cache --no-color --color

  assert_failure
  assert_output --partial '--color and --no-color are mutually exclusive'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache works without the key (no API access)" {
  unset KRISP_API_KEY
  TERMINATOR_KRISP_CACHE_DIR="$(mktemp -d)"

  run terminator::krisp::cache

  assert_success
  assert_output --partial "Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}"
  assert_output --partial '0 transcripts, 0B total'
}

################################################################################
# terminator::krisp::__cache_filename__ / __render_markdown__
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ builds the lexical name from a meeting response" {
  run terminator::krisp::__cache_filename__ "${KRISP_MEETING_JSON}"

  assert_success
  assert_output '2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__Weekly-sync.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ truncates a millisecond started_at to second precision" {
  local ms_body
  ms_body="$(jq '.started_at = "2026-07-10T09:30:00.476Z"' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__cache_filename__ "${ms_body}"

  assert_success
  assert_output '2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__Weekly-sync.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ sanitizes a desktop-style title to a slug" {
  local titled_body
  titled_body="$(jq --arg t 'RE: Corvex <> Helios Oppty -> 4Q26 deployment' '.title = $t' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__cache_filename__ "${titled_body}"

  assert_success
  assert_output '2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__RE-Corvex-Helios-Oppty-4Q26-deployment.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ falls back to untitled for empty and symbol-only titles" {
  local empty_body symbol_body
  empty_body="$(jq '.title = ""' <<<"${KRISP_MEETING_JSON}")"
  symbol_body="$(jq --arg t '!!! <>' '.title = $t' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__cache_filename__ "${empty_body}"

  assert_success
  assert_output '2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__untitled.md'

  run terminator::krisp::__cache_filename__ "${symbol_body}"

  assert_success
  assert_output '2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__untitled.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ truncates the slug to 80 chars without a trailing hyphen" {
  local \
    long_body \
    expected
  long_body="$(jq --arg t "$(printf 'b%.0s' {1..79})!!c" '.title = $t' <<<"${KRISP_MEETING_JSON}")"
  expected="2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__$(printf 'b%.0s' {1..79}).md"

  run terminator::krisp::__cache_filename__ "${long_body}"

  assert_success
  assert_output "${expected}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ collapses non-ASCII characters in the slug" {
  local unicode_body
  unicode_body="$(jq --arg t 'Café sync' '.title = $t' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__cache_filename__ "${unicode_body}"

  assert_success
  assert_output '2026-07-10T09-30-00Z__aabbccddeeff00112233445566778899__Caf-sync.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_filename
@test "__cache_filename__ defaults a missing started_at to the epoch" {
  local epoch_body
  epoch_body="$(jq 'del(.started_at)' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__cache_filename__ "${epoch_body}"

  assert_success
  assert_output '1970-01-01T00-00-00Z__aabbccddeeff00112233445566778899__Weekly-sync.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ renders the frontmatter header and the transcript" {
  run terminator::krisp::__render_markdown__ "${KRISP_MEETING_JSON}"

  assert_success
  assert_output "---
doc_type: transcript
id: aabbccddeeff00112233445566778899
title: \"Weekly sync\"
started_at: 2026-07-10T09:30:00Z
duration: 1h 0m 0s
language: en
---

# Weekly sync

Casey Rivera [00:00:05]: lets get started
sam@example.com [00:00:11]: sounds good
Speaker 3 [00:01:00]: unidentified voice
Casey Rivera [01:02:05]: wrapping up"
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ renders a Hill Valley meeting from 1955" {
  local delorean_body
  # Millisecond started_at, a YAML-breaking title, and Doc and Marty.
  delorean_body="$(jq --arg t 'Flux capacitor: getting the DeLorean to 88' '
    .title = $t
    | .started_at = "1955-11-12T22:04:00.000Z"
    | .duration = 5280
    | .transcript.speakers = {"1": {"first_name": "Emmett", "last_name": "Brown"}, "2": {"first_name": "Marty", "last_name": "McFly"}}
    | .transcript.segments = [
        {"speaker": 1, "text": "Great Scott!", "start": 1, "end": 2},
        {"speaker": 2, "text": "Doc, this is heavy.", "start": 3, "end": 4},
        {"speaker": 1, "text": "When this baby hits 88 miles per hour, you are gonna see some serious...", "start": 5, "end": 9},
        {"speaker": 2, "text": "1.21 gigawatts?!", "start": 10, "end": 11}
      ]
  ' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${delorean_body}"

  assert_success
  assert_output "---
doc_type: transcript
id: aabbccddeeff00112233445566778899
title: \"Flux capacitor: getting the DeLorean to 88\"
started_at: 1955-11-12T22:04:00Z
duration: 1h 28m 0s
language: en
---

# Flux capacitor: getting the DeLorean to 88

Emmett Brown [00:00:01]: Great Scott!
Marty McFly [00:00:03]: Doc, this is heavy.
Emmett Brown [00:00:05]: When this baby hits 88 miles per hour, you are gonna see some serious...
Marty McFly [00:00:10]: 1.21 gigawatts?!"
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ quotes a title with YAML-breaking characters" {
  local special_body
  special_body="$(jq --arg t 'RE: Corvex -> Helios Oppty <4Q26>' '.title = $t' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${special_body}"

  assert_success
  # tojson quotes the title; the H1 keeps the raw title greppable.
  assert_output --partial 'title: "RE: Corvex -> Helios Oppty <4Q26>"'
  assert_output --partial '# RE: Corvex -> Helios Oppty <4Q26>'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ omits duration and language when absent" {
  local bare_body
  bare_body="$(jq 'del(.duration) | del(.transcript.language)' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${bare_body}"

  assert_success
  refute_output --partial 'duration:'
  refute_output --partial 'language:'
  assert_output --partial 'title: "Weekly sync"'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ omits a zero duration" {
  local zero_body
  zero_body="$(jq '.duration = 0' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${zero_body}"

  assert_success
  refute_output --partial 'duration:'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ formats sub-hour and multi-hour durations" {
  local \
    short_body \
    long_body

  short_body="$(jq '.duration = 3135' <<<"${KRISP_MEETING_JSON}")"
  long_body="$(jq '.duration = 7335' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${short_body}"
  assert_success
  assert_output --partial 'duration: 52m 15s'

  run terminator::krisp::__render_markdown__ "${long_body}"
  assert_success
  assert_output --partial 'duration: 2h 2m 15s'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ floors a fractional duration" {
  local frac_body
  # 88 mph, and a half second to spare.
  frac_body="$(jq '.duration = 88.5' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${frac_body}"

  assert_success
  assert_output --partial 'duration: 1m 28s'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ tolerates a non-object transcript" {
  local stringy_body
  stringy_body="$(jq '.transcript = "this is heavy"' <<<"${KRISP_MEETING_JSON}")"

  run terminator::krisp::__render_markdown__ "${stringy_body}"

  # The language guard must not abort the render; the entry stays complete.
  assert_success
  refute_output --partial 'language:'
  assert_output --partial '# Weekly sync'
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ with TAGS renders a sorted, deduped tags line last" {
  local rendered
  terminator::krisp::__render_markdown__ "${KRISP_MEETING_JSON}" rendered 'zeta,alpha,zeta'

  # Tags land after language and before the closing delimiter.
  [[ "$(sed -n '7p' <<<"${rendered}")" == 'language: en' ]]
  [[ "$(sed -n '8p' <<<"${rendered}")" == 'tags: [alpha, zeta]' ]]
  [[ "$(sed -n '9p' <<<"${rendered}")" == '---' ]]

  # Whitespace around comma-separated values is trimmed.
  terminator::krisp::__render_markdown__ "${KRISP_MEETING_JSON}" rendered ' beta , alpha '
  [[ "$(sed -n '8p' <<<"${rendered}")" == 'tags: [alpha, beta]' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::render_markdown
@test "__render_markdown__ without TAGS stays byte-identical" {
  local \
    with_arg \
    without_arg

  terminator::krisp::__render_markdown__ "${KRISP_MEETING_JSON}" with_arg ''
  terminator::krisp::__render_markdown__ "${KRISP_MEETING_JSON}" without_arg

  [[ "${with_arg}" == "${without_arg}" ]]
  [[ "$(sed -n '8p' <<<"${without_arg}")" == '---' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_write
@test "__cache_write__ with TAGS lands the tags line in the entry" {
  _krisp_env

  terminator::krisp::__cache_write__ aabbccddeeff00112233445566778899 "${KRISP_MEETING_JSON}" 'work'

  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  [[ "$(sed -n '8p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")" == 'tags: [work]' ]]
  [[ "$(sed -n '9p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")" == '---' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_entry_valid
@test "__cache_entry_valid__ accepts frontmatter and legacy headers" {
  local \
    frontmatter_entry \
    legacy_entry

  frontmatter_entry='---
doc_type: transcript
id: aabbccddeeff00112233445566778899
title: "Weekly sync"
started_at: 2026-07-10T09:30:00Z
duration: 1h 0m 0s
language: en
---

# Weekly sync

Casey Rivera [00:00:05]: lets get started'

  legacy_entry='# Weekly sync
2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)

Casey Rivera [00:00:05]: lets get started'

  run terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "${frontmatter_entry}"
  assert_success

  run terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "${legacy_entry}"
  assert_success
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_entry_valid
@test "__cache_entry_valid__ rejects a wrong id in either format" {
  local \
    frontmatter_entry \
    legacy_entry

  frontmatter_entry='---
doc_type: transcript
id: 99887766554433221100ffeeddccbbaa
title: "Design review"
---

# Design review'

  legacy_entry='# Design review
2026-07-11T14:00:00Z (id 99887766554433221100ffeeddccbbaa)'

  run terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "${frontmatter_entry}"
  assert_failure

  run terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "${legacy_entry}"
  assert_failure
}

################################################################################
# terminator::krisp::__tag_valid__ / __date_valid__ / __date_next__
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::tag_valid
@test "__tag_valid__ accepts alnum-anchored values and rejects others" {
  run terminator::krisp::__tag_valid__ work
  assert_success

  run terminator::krisp::__tag_valid__ 'q3-roadmap.v2'
  assert_success

  run terminator::krisp::__tag_valid__ ''
  assert_failure

  run terminator::krisp::__tag_valid__ '-work'
  assert_failure

  run terminator::krisp::__tag_valid__ 'two words'
  assert_failure
  assert_output --partial "krisp: invalid tag 'two words'"
}

# bats test_tags=terminator::krisp,terminator::krisp::date_next
@test "__date_next__ rolls over months and years" {
  run terminator::krisp::__date_next__ 2026-01-31
  assert_success
  assert_output '2026-02-01'

  run terminator::krisp::__date_next__ 2026-12-31
  assert_success
  assert_output '2027-01-01'
}

# bats test_tags=terminator::krisp,terminator::krisp::date_next
@test "__date_next__ handles February normal and leap years" {
  run terminator::krisp::__date_next__ 2024-02-28
  assert_success
  assert_output '2024-02-29'

  run terminator::krisp::__date_next__ 2026-02-28
  assert_success
  assert_output '2026-03-01'
}

# bats test_tags=terminator::krisp,terminator::krisp::date_next
@test "__date_next__ applies the century leap rule" {
  run terminator::krisp::__date_next__ 2000-02-28
  assert_success
  assert_output '2000-02-29'

  run terminator::krisp::__date_next__ 1900-02-28
  assert_success
  assert_output '1900-03-01'
}

# bats test_tags=terminator::krisp,terminator::krisp::date_next
@test "__date_next__ rejects invalid shapes and calendar dates" {
  run terminator::krisp::__date_next__ 2026-2-28
  assert_failure

  run terminator::krisp::__date_next__ 2026-13-01
  assert_failure

  run terminator::krisp::__date_next__ 2026-00-10
  assert_failure

  run terminator::krisp::__date_next__ 2026-02-30
  assert_failure

  run terminator::krisp::__date_next__ 2026-02-00
  assert_failure

  run terminator::krisp::__date_next__ 'not-a-date'
  assert_failure
}

# bats test_tags=terminator::krisp,terminator::krisp::date_next
@test "__date_next__ writes to an output variable" {
  local next
  terminator::krisp::__date_next__ 2026-09-30 next

  [[ "${next}" == '2026-10-01' ]]

  run terminator::krisp::__date_next__ 2026-09-30
  assert_success
  assert_output '2026-10-01'
}

# bats test_tags=terminator::krisp,terminator::krisp::date_valid
@test "__date_valid__ accepts calendar dates and rejects impossible ones" {
  run terminator::krisp::__date_valid__ 2024-02-29
  assert_success

  run terminator::krisp::__date_valid__ 2026-09-24
  assert_success

  run terminator::krisp::__date_valid__ 2026-02-29
  assert_failure

  run terminator::krisp::__date_valid__ 2026-02-30
  assert_failure

  run terminator::krisp::__date_valid__ '2026-9-24'
  assert_failure
}

################################################################################
# terminator::krisp::__cache_entries_in_range__
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::cache_entries_in_range
@test "__cache_entries_in_range__ collects in-range entries oldest first" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"
  # Old-grammar filenames stay invisible until a krisp-cache view
  # migrates them.
  printf '%s\n' 'stale' >"${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_deadbeefdeadbeefdeadbeefdeadbeef_Stale.md"

  local \
    out \
    expected

  # A single day is [D, D+1).
  terminator::krisp::__cache_entries_in_range__ out '2026-07-10' '2026-07-11'
  [[ "${out}" == "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]

  terminator::krisp::__cache_entries_in_range__ out '2026-07-11' '2026-07-12'
  [[ "${out}" == "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}" ]]

  # A wider range collects both, oldest first.
  expected="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}
${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  terminator::krisp::__cache_entries_in_range__ out '2026-07-10' '2026-07-12'
  [[ "${out}" == "${expected}" ]]

  # Empty range and open bounds.
  terminator::krisp::__cache_entries_in_range__ out '2026-07-12' '2026-07-13'
  [[ -z "${out}" ]]

  terminator::krisp::__cache_entries_in_range__ out
  [[ "${out}" == "${expected}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_entries_in_range
@test "__cache_entries_in_range__ accepts ISO bounds and resolves duplicate ids" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  # A same-id entry under a later lexical name: the first filename wins.
  printf '%s\n' 'dup' >"${TERMINATOR_KRISP_CACHE_DIR}/2026-07-11T15-00-00Z__aabbccddeeff00112233445566778899__dup.md"

  local out

  terminator::krisp::__cache_entries_in_range__ out '2026-07-10' '2026-07-12'
  [[ "${out}" == "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]

  # ISO timestamps normalize to the filename grammar.
  terminator::krisp::__cache_entries_in_range__ out '2026-07-10T09:30:00' '2026-07-10T09:31:00'
  [[ "${out}" == "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]

  terminator::krisp::__cache_entries_in_range__ out '2026-07-10T09:31:00' '2026-07-10T09:32:00'
  [[ -z "${out}" ]]
}

################################################################################
# terminator::krisp::__cache_entry_tags__ / __cache_retag__
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::cache_entry_tags
@test "__cache_entry_tags__ reads the flow list, empty for missing and legacy" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'language: en' \
    'tags: [alpha, beta]' \
    '---' \
    '' \
    '# Weekly sync' \
    >"${tagged}"

  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_success
  assert_output 'alpha, beta'

  # A missing tags line reads as empty.
  sed -i '/^tags: /d' "${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_success
  assert_output ''

  # Only the frontmatter block counts: a body line never spoofs the field.
  printf '%s\n' \
    'tags: [spoofed]' \
    >>"${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_success
  assert_output ''

  # A legacy two-line header has no frontmatter, so no tags.
  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_entry_tags
@test "__cache_entry_tags__ rejects malformed tags values" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha, beta' \
    '---' \
    >"${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_failure

  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha, -bad]' \
    '---' \
    >"${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_failure

  # Two tags lines.
  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha]' \
    'tags: [beta]' \
    '---' \
    >"${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_failure

  # An unterminated frontmatter block.
  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha]' \
    >"${tagged}"
  run terminator::krisp::__cache_entry_tags__ "${tagged}"
  assert_failure
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ merges into an untagged frontmatter entry" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'duration: 1h 0m 0s' \
    'language: en' \
    '---' \
    '' \
    '# Weekly sync' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${tagged}"

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_success
  assert_output ''

  # Tags land as the last field before the closing delimiter, the entry
  # stays valid, and the write leaves no tmp residue.
  [[ "$(sed -n '8p' "${tagged}")" == 'tags: [work]' ]]
  [[ "$(sed -n '9p' "${tagged}")" == '---' ]]
  terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "$(cat "${tagged}")"
  [[ -z "$(find "${TERMINATOR_KRISP_CACHE_DIR}" -name '*.tmp*')" ]]

  # The body below the frontmatter is unchanged.
  [[ "$(tail -n +10 "${tagged}")" == $'\n# Weekly sync\n\nCasey Rivera [00:00:05]: lets get started' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ merges into an existing flow list and is idempotent" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'tags: [alpha]' \
    '---' \
    >"${tagged}"

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 beta
  assert_success

  grep -qxF 'tags: [alpha, beta]' "${tagged}"

  # Re-running with either tag writes nothing: bytes unchanged.
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 alpha
  assert_success
  [[ "$(cat "${tagged}")" == "${before}" ]]

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 beta
  assert_success
  [[ "$(cat "${tagged}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ upgrades a legacy header around a byte-unchanged body" {
  _krisp_env
  local legacy="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${legacy}"

  run terminator::krisp::__cache_retag__ "${legacy}" aabbccddeeff00112233445566778899 work
  assert_success
  assert_output ''

  # Synthesized frontmatter carries the old title and started_at.
  [[ "$(sed -n '1p' "${legacy}")" == '---' ]]
  [[ "$(sed -n '2p' "${legacy}")" == 'doc_type: transcript' ]]
  [[ "$(sed -n '3p' "${legacy}")" == 'id: aabbccddeeff00112233445566778899' ]]
  [[ "$(sed -n '4p' "${legacy}")" == 'title: "Weekly sync"' ]]
  [[ "$(sed -n '5p' "${legacy}")" == 'started_at: 2026-07-10T09:30:00Z' ]]
  [[ "$(sed -n '6p' "${legacy}")" == 'tags: [work]' ]]
  [[ "$(sed -n '7p' "${legacy}")" == '---' ]]

  # The body below the header is byte-unchanged and the entry stays valid.
  [[ "$(tail -n +8 "${legacy}")" == $'\nCasey Rivera [00:00:05]: lets get started' ]]
  terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "$(cat "${legacy}")"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ escapes a quoted title and defaults an empty one" {
  _krisp_env
  local legacy="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '# Review of "the plan" \ draft v2' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${legacy}"

  run terminator::krisp::__cache_retag__ "${legacy}" aabbccddeeff00112233445566778899 work
  assert_success

  # The quoting matches the render path's jq tojson.
  [[ "$(sed -n '4p' "${legacy}")" == 'title: "Review of \"the plan\" \\ draft v2"' ]]

  # An empty legacy title renders (untitled) like the render path.
  printf '%s\n' \
    '# ' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    >"${legacy}"

  run terminator::krisp::__cache_retag__ "${legacy}" aabbccddeeff00112233445566778899 work
  assert_success
  [[ "$(sed -n '4p' "${legacy}")" == 'title: "(untitled)"' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ refuses corrupt and malformed entries without writing" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # An entry matching neither format.
  printf '%s\n' \
    'not markdown' \
    'at all' \
    >"${tagged}"
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_failure
  assert_output --partial "krisp: cannot retag '${tagged}'"
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # A malformed tags line in a frontmatter entry.
  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha' \
    '---' \
    >"${tagged}"
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_failure
  assert_output --partial "krisp: cannot retag '${tagged}'"
  [[ "$(cat "${tagged}")" == "${before}" ]]
  [[ -z "$(find "${TERMINATOR_KRISP_CACHE_DIR}" -name '*.tmp*')" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ refuses a legacy entry whose id marker does not end line 2" {
  _krisp_env
  local legacy="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # Valid shape, but the id marker is not the end of line 2.
  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899) trailing' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${legacy}"
  local before
  before="$(cat "${legacy}")"

  run terminator::krisp::__cache_retag__ "${legacy}" aabbccddeeff00112233445566778899 work

  assert_failure
  assert_output --partial "krisp: cannot retag '${legacy}'"
  [[ "$(cat "${legacy}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ refuses a corrupt entry even when the tag is already present" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # Frontmatter naming a different meeting id: valid shape, wrong id, with
  # the tag already present.
  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: 11111111111111111111111111111111' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'tags: [work]' \
    '---' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${tagged}"
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_retag__ "${tagged}" aabbccddeeff00112233445566778899 work

  assert_failure
  assert_output --partial "krisp: cannot retag '${tagged}'"
  [[ "$(cat "${tagged}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_retag
@test "__cache_retag__ rejects an invalid tag before touching the entry" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  _seed_cache "${KRISP_MEETING_JSON}"
  local before
  before="$(cat "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")"

  run terminator::krisp::__cache_retag__ "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" aabbccddeeff00112233445566778899 '-bad'
  assert_failure
  assert_output --partial "krisp: invalid tag '-bad'"
  [[ "$(cat "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_set_tags
@test "__cache_set_tags__ rewrites the tags list sorted and deduped" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'duration: 1h 0m 0s' \
    'language: en' \
    '---' \
    >"${tagged}"

  # The rewrite sorts, dedupes, and drops empty entries; the tags line
  # lands as the last field before the closing delimiter.
  run terminator::krisp::__cache_set_tags__ "${tagged}" aabbccddeeff00112233445566778899 'zeta, alpha, zeta, , beta'
  assert_success
  assert_output ''

  [[ "$(sed -n '8p' "${tagged}")" == 'tags: [alpha, beta, zeta]' ]]
  [[ "$(sed -n '9p' "${tagged}")" == '---' ]]
  terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "$(cat "${tagged}")"
  [[ -z "$(find "${TERMINATOR_KRISP_CACHE_DIR}" -name '*.tmp*')" ]]

  # An empty list omits the tags line entirely, byte-identical to the
  # tagless render.
  _seed_cache "${KRISP_MEETING_JSON}"
  local tagless
  tagless="$(cat "${tagged}")"
  _seed_cache "${KRISP_MEETING_JSON}" work

  run terminator::krisp::__cache_set_tags__ "${tagged}" aabbccddeeff00112233445566778899 ''
  assert_success
  assert_output ''
  [[ "$(cat "${tagged}")" == "${tagless}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_set_tags
@test "__cache_set_tags__ upgrades a legacy header like retag does" {
  _krisp_env
  local legacy="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${legacy}"

  run terminator::krisp::__cache_set_tags__ "${legacy}" aabbccddeeff00112233445566778899 'work, review'
  assert_success
  assert_output ''

  [[ "$(sed -n '6p' "${legacy}")" == 'tags: [review, work]' ]]
  [[ "$(sed -n '7p' "${legacy}")" == '---' ]]
  [[ "$(tail -n +8 "${legacy}")" == $'\nCasey Rivera [00:00:05]: lets get started' ]]
  terminator::krisp::__cache_entry_valid__ aabbccddeeff00112233445566778899 "$(cat "${legacy}")"

  # An empty list upgrades without a tags line at all.
  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${legacy}"

  run terminator::krisp::__cache_set_tags__ "${legacy}" aabbccddeeff00112233445566778899 ''
  assert_success
  [[ "$(sed -n '6p' "${legacy}")" == '---' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_set_tags
@test "__cache_set_tags__ is silent on a corrupt entry" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  printf '%s\n' 'not markdown' 'at all' >"${tagged}"

  # The core is silent: the caller owns the error message.
  run terminator::krisp::__cache_set_tags__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_failure
  assert_output ''
  [[ "$(cat "${tagged}")" == $'not markdown\nat all' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_untag
@test "__cache_untag__ removes a tag, re-sorts, and is idempotent" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  _seed_cache "${KRISP_MEETING_JSON}" 'zeta, work, alpha'

  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_success
  assert_output ''

  grep -qxF 'tags: [alpha, zeta]' "${tagged}"

  # Re-running an absent tag writes nothing.
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_success
  assert_output ''
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # Removing the last tag omits the tags line entirely, byte-identical
  # to the tagless render.
  _seed_cache "${KRISP_MEETING_JSON}"
  local tagless
  tagless="$(cat "${tagged}")"
  _seed_cache "${KRISP_MEETING_JSON}" 'alpha, zeta'

  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 alpha
  assert_success
  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 zeta
  assert_success
  [[ "$(cat "${tagged}")" == "${tagless}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_untag
@test "__cache_untag__ skips legacy entries and refuses invalid ones without writing" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # A legacy entry carries no tags, so removing is a no-op.
  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${tagged}"
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_success
  assert_output ''
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # A corrupt entry is refused.
  printf '%s\n' 'not markdown' 'at all' >"${tagged}"
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_failure
  assert_output --partial "krisp: cannot untag '${tagged}'"
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # A malformed tags value is refused.
  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha' \
    '---' \
    >"${tagged}"
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 work
  assert_failure
  assert_output --partial "krisp: cannot untag '${tagged}'"
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # An invalid tag is refused before touching the entry.
  run terminator::krisp::__cache_untag__ "${tagged}" aabbccddeeff00112233445566778899 '-bad'
  assert_failure
  assert_output --partial "krisp: invalid tag '-bad'"
  [[ "$(cat "${tagged}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_rename_tag
@test "__cache_rename_tag__ renames, re-sorts, and dedupes into NEW" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  _seed_cache "${KRISP_MEETING_JSON}" 'zeta, work, alpha'

  run terminator::krisp::__cache_rename_tag__ "${tagged}" aabbccddeeff00112233445566778899 work review
  assert_success
  assert_output ''

  grep -qxF 'tags: [alpha, review, zeta]' "${tagged}"

  # A NEW already present elsewhere in the list leaves OLD simply
  # dropped by the dedupe.
  _seed_cache "${KRISP_MEETING_JSON}" 'zeta, work, alpha'

  run terminator::krisp::__cache_rename_tag__ "${tagged}" aabbccddeeff00112233445566778899 alpha zeta
  assert_success
  grep -qxF 'tags: [work, zeta]' "${tagged}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_rename_tag
@test "__cache_rename_tag__ skips a missing OLD and refuses malformed entries" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # OLD absent from the entry: exit 2, no write, no output.
  _seed_cache "${KRISP_MEETING_JSON}" work
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_rename_tag__ "${tagged}" aabbccddeeff00112233445566778899 review retro
  assert_failure 2
  assert_output ''
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # A malformed tags value is refused.
  printf '%s\n' \
    '---' \
    'id: aabbccddeeff00112233445566778899' \
    'tags: [alpha' \
    '---' \
    >"${tagged}"
  before="$(cat "${tagged}")"

  run terminator::krisp::__cache_rename_tag__ "${tagged}" aabbccddeeff00112233445566778899 work review
  assert_failure
  assert_output --partial "krisp: cannot rename tag in '${tagged}'"
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # An invalid NEW tag is refused before touching the entry.
  run terminator::krisp::__cache_rename_tag__ "${tagged}" aabbccddeeff00112233445566778899 work '-bad'
  assert_failure
  assert_output --partial "krisp: invalid tag '-bad'"
  [[ "$(cat "${tagged}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_vocabulary
@test "__tag_vocabulary__ collects the distinct sorted tags across entries" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local tagged2="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  # An empty library yields an empty vocabulary.
  local vocab
  terminator::krisp::__tag_vocabulary__ vocab
  [[ "${vocab}" == '' ]]

  _seed_cache "${KRISP_MEETING_JSON}" 'zeta, work'
  _seed_cache "${KRISP_MEETING2_JSON}" 'alpha, work'

  # Whole library: distinct tags, LC_ALL=C sorted, one per line.
  terminator::krisp::__tag_vocabulary__ vocab
  [[ "${vocab}" == $'alpha\nwork\nzeta' ]]

  # A selection scopes the vocabulary to those entries.
  terminator::krisp::__tag_vocabulary__ vocab "${tagged}"
  [[ "${vocab}" == $'work\nzeta' ]]

  # Untagged entries contribute nothing.
  _seed_cache "${KRISP_MEETING_JSON}"
  terminator::krisp::__tag_vocabulary__ vocab
  [[ "${vocab}" == $'alpha\nwork' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_vocabulary
@test "__tag_vocabulary__ skips malformed and legacy entries like the view does" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local tagged2="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  _seed_cache "${KRISP_MEETING_JSON}" work

  # A malformed tags value in a neighbor entry is skipped, not fatal.
  printf '%s\n' \
    '---' \
    'id: 99887766554433221100ffeeddccbbaa' \
    'tags: [alpha' \
    '---' \
    >"${tagged2}"

  # A legacy entry contributes nothing.
  printf '%s\n' \
    '# Retro' \
    '2026-07-09T16:00:00Z (id 5566778899aabbccddeeff0011223344)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/2026-07-09T16-00-00Z__5566778899aabbccddeeff0011223344__Retro.md"

  local vocab
  terminator::krisp::__tag_vocabulary__ vocab
  [[ "${vocab}" == 'work' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_apply
@test "__tag_apply__ tags and untags a selection with count summaries" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local tagged2="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  local selection
  selection="$(printf '%s\n%s' "${tagged}" "${tagged2}")"

  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::__tag_apply__ add 'work, review' "${selection}"
  assert_success
  assert_output "Tagged 2 transcripts with 'work, review'"

  grep -qxF 'tags: [review, work]' "${tagged}"
  grep -qxF 'tags: [review, work]' "${tagged2}"

  run terminator::krisp::__tag_apply__ rm 'work, review' "${selection}"
  assert_success
  assert_output "Removed 'work, review' from 2 transcripts"

  run ! grep -q '^tags: ' "${tagged}"
  run ! grep -q '^tags: ' "${tagged2}"

  # Singular at one, nothing at zero.
  run terminator::krisp::__tag_apply__ add work "${tagged}"
  assert_success
  assert_output "Tagged 1 transcript with 'work'"

  run terminator::krisp::__tag_apply__ add work ''
  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_apply
@test "__tag_apply__ skips a failed entry, continues, and returns 1" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local tagged2="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  local selection
  selection="$(printf '%s\n%s' "${tagged}" "${tagged2}")"

  _seed_cache "${KRISP_MEETING_JSON}"
  printf '%s\n' 'not markdown' 'at all' >"${tagged2}"
  local before
  before="$(cat "${tagged2}")"

  run terminator::krisp::__tag_apply__ add work "${selection}"
  assert_failure
  assert_output --partial "Tagged 1 transcript with 'work'"
  assert_output --partial "krisp: cannot retag '${tagged2}'"

  grep -qxF 'tags: [work]' "${tagged}"
  [[ "$(cat "${tagged2}")" == "${before}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_apply
@test "__tag_apply__ rejects an unknown verb" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::__tag_apply__ bogus work "${tagged}"
  assert_failure 2
  assert_output ''
  run ! grep -q '^tags: ' "${tagged}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_rename
@test "__tag_rename__ renames a tag across the library with count summaries" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local tagged2="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  _seed_cache "${KRISP_MEETING_JSON}" 'work, zeta'
  _seed_cache "${KRISP_MEETING2_JSON}" 'work, alpha'

  run terminator::krisp::__tag_rename__ work review
  assert_success
  assert_output "Renamed 'work' to 'review' in 2 transcripts"

  grep -qxF 'tags: [review, zeta]' "${tagged}"
  grep -qxF 'tags: [alpha, review]' "${tagged2}"

  # Entries not carrying OLD are normal skips; only carries count.
  _seed_cache "${KRISP_MEETING_JSON}" work

  run terminator::krisp::__tag_rename__ work review
  assert_success
  assert_output "Renamed 'work' to 'review' in 1 transcript"

  grep -qxF 'tags: [review]' "${tagged}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag_rename
@test "__tag_rename__ notices a tag nothing carries and fails through bad entries" {
  _krisp_env
  local tagged="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local tagged2="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  # A tag no entry carries: notice, exit 1, nothing written.
  _seed_cache "${KRISP_MEETING_JSON}" work
  local before
  before="$(cat "${tagged}")"

  run terminator::krisp::__tag_rename__ review retro
  assert_failure
  assert_output --partial "no cached transcript carries 'review'"
  [[ "$(cat "${tagged}")" == "${before}" ]]

  # An invalid tag is refused up front.
  run terminator::krisp::__tag_rename__ '-bad' work
  assert_failure
  assert_output --partial "krisp: invalid tag '-bad'"

  # A malformed entry fails the run while good entries still rename.
  _seed_cache "${KRISP_MEETING_JSON}" work
  printf '%s\n' 'not markdown' 'at all' >"${tagged2}"
  before="$(cat "${tagged2}")"

  run terminator::krisp::__tag_rename__ work review
  assert_failure
  assert_output --partial "Renamed 'work' to 'review' in 1 transcript"
  assert_output --partial "krisp: cannot rename tag in '${tagged2}'"

  grep -qxF 'tags: [review]' "${tagged}"
  [[ "$(cat "${tagged2}")" == "${before}" ]]
}

################################################################################
# terminator::krisp::__meetings__ (mocked curl)
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::meetings
@test "__meetings__ filters rows to the strict date range" {
  _krisp_env
  _krisp_curl_ok
  local out

  # The API's from/to bounds each include the whole bound day; the filter is
  # strict: started_at from FROM on, before TO.
  terminator::krisp::__meetings__ out 0 '2026-07-10' '2026-07-11'
  [[ "$(jq -r '.[].id' <<<"${out}")" == 'aabbccddeeff00112233445566778899' ]]

  terminator::krisp::__meetings__ out 0 '' '2026-07-10'
  [[ "$(jq -r '.[].id' <<<"${out}")" == '5566778899aabbccddeeff0011223344' ]]

  terminator::krisp::__meetings__ out 0 '2026-07-10' ''
  [[ "$(jq -r '.[].id' <<<"${out}")" == '99887766554433221100ffeeddccbbaa
aabbccddeeff00112233445566778899' ]]

  # No bounds: every row passes through in the API's newest-first order.
  terminator::krisp::__meetings__ out 0 '' ''
  [[ "$(jq -r '.[].id' <<<"${out}")" == '99887766554433221100ffeeddccbbaa
aabbccddeeff00112233445566778899
5566778899aabbccddeeff0011223344' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::meetings
@test "__meetings__ accepts ISO timestamp bounds" {
  _krisp_env
  _krisp_curl_ok
  local out

  terminator::krisp::__meetings__ out 0 '2026-07-10T12:00:00Z' '2026-07-11T15:00:00Z'
  [[ "$(jq -r '.[].id' <<<"${out}")" == '99887766554433221100ffeeddccbbaa' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::meetings
@test "__meetings__ counts only in-range rows against the limit" {
  _krisp_env
  query_log="$(mktemp)"

  # Page 1: an out-of-range next-day meeting plus a cursor; page 2: the
  # in-range one. The limit must page past the out-of-range row.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n' "$*" >>"${query_log}"
    case "$*" in
      *'cursor=page2'*)
        printf '%s\n%s\n' "${KRISP_PAGE2_JSON}" '200'
        ;;
      *)
        printf '%s\n%s\n' "${KRISP_PAGE1_JSON}" '200'
        ;;
    esac
  }

  local out
  terminator::krisp::__meetings__ out 1 '2026-07-10' '2026-07-11'

  (($(jq 'length' <<<"${out}") == 1))
  [[ "$(jq -r '.[0].id' <<<"${out}")" == 'aabbccddeeff00112233445566778899' ]]
  grep -q -- 'cursor=page2' "${query_log}"
}

################################################################################
# terminator::krisp::list (mocked curl)
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list prints one row per meeting" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::list

  assert_success
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
  assert_output --partial '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  Design review'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list marks meetings that are not ready" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::list

  assert_success
  assert_output --partial 'Retro  [processing]'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list passes the limit and sort to the API" {
  _krisp_env
  query_log="$(mktemp)"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n' "$*" >"${query_log}"
    printf '%s\n%s\n' "${KRISP_LIST_JSON}" '200'
  }

  run terminator::krisp::list --limit 5

  assert_success
  grep -q -- 'limit=5' "${query_log}"
  grep -q -- 'order=newest' "${query_log}"
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list paginates through a next_cursor" {
  _krisp_env
  query_log="$(mktemp)"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n' "$*" >>"${query_log}"
    case "$*" in
      *'cursor=page2'*)
        printf '%s\n%s\n' "${KRISP_PAGE2_JSON}" '200'
        ;;
      *)
        printf '%s\n%s\n' "${KRISP_PAGE1_JSON}" '200'
        ;;
    esac
  }

  run terminator::krisp::list --limit 2

  assert_success
  # Both pages contribute a row.
  assert_output --partial '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  Design review'
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
  # The second page was requested with the cursor from the first.
  grep -q -- 'cursor=page2' "${query_log}"
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --since and --until pass the dates to the API" {
  _krisp_env
  query_log="$(mktemp)"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n' "$*" >"${query_log}"
    printf '%s\n%s\n' "${KRISP_LIST_JSON}" '200'
  }

  run terminator::krisp::list --since 2026-07-01 --until 2026-07-11

  assert_success
  grep -q -- 'from=2026-07-01' "${query_log}"
  grep -q -- 'to=2026-07-11' "${query_log}"
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --on passes the day range to the API" {
  _krisp_env
  query_log="$(mktemp)"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n' "$*" >"${query_log}"
    printf '%s\n%s\n' "${KRISP_LIST_JSON}" '200'
  }

  run terminator::krisp::list --on 2026-07-10

  assert_success
  grep -q -- 'from=2026-07-10' "${query_log}"
  grep -q -- 'to=2026-07-11' "${query_log}"
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --on output carries no tags" {
  _krisp_env
  _krisp_curl_ok
  # A tagged cache entry must not leak into the API-pure list view.
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  run terminator::krisp::list --on 2026-07-10

  assert_success
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
  refute_output --partial 'tags:'
  refute_output --partial '[work]'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list date bounds are strict despite the inclusive API" {
  _krisp_env
  _krisp_curl_ok

  # The mock answers every query with all three meetings, like an API whose
  # to bound includes the whole to-day; the bounds must stay strict.
  run terminator::krisp::list --on 2026-07-10
  assert_success
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
  refute_output --partial 'Design review'
  refute_output --partial 'Retro'

  run terminator::krisp::list --until 2026-07-10
  assert_success
  assert_output --partial '2026-07-09T16:00Z  5566778899aabbccddeeff0011223344  Retro'
  refute_output --partial 'Weekly sync'
  refute_output --partial 'Design review'

  run terminator::krisp::list --since 2026-07-10
  assert_success
  assert_output --partial '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  Design review'
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
  refute_output --partial 'Retro'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --on is exclusive with --since and --until" {
  _krisp_env

  run terminator::krisp::list --on 2026-07-10 --since 2026-07-10

  assert_failure
  assert_output --partial 'exclusive with --since and --until'

  run terminator::krisp::list --on 2026-07-10 --until 2026-07-11

  assert_failure
  assert_output --partial 'exclusive with --since and --until'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list rejects a value-taking flag with no value" {
  _krisp_env

  run terminator::krisp::list --limit
  assert_failure
  assert_output --partial '--limit requires a number'

  run terminator::krisp::list --since
  assert_failure
  assert_output --partial '--since requires a date'

  run terminator::krisp::list --until
  assert_failure
  assert_output --partial '--until requires a date'

  run terminator::krisp::list --on
  assert_failure
  assert_output --partial '--on requires a date'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --on rejects an invalid date" {
  _krisp_env

  run terminator::krisp::list --on 2026-02-30

  assert_failure
  assert_output --partial "invalid date: '2026-02-30'"
  assert_output --partial 'expected YYYY-MM-DD'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --since rejects an invalid date" {
  _krisp_env

  run terminator::krisp::list --since Sept-1

  assert_failure
  assert_output --partial "invalid date: 'Sept-1'"
  assert_output --partial 'expected YYYY-MM-DD or ISO timestamp'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --since without --limit pages until exhausted" {
  _krisp_env
  query_log="$(mktemp)"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n' "$*" >>"${query_log}"
    case "$*" in
      *'cursor=page2'*)
        printf '%s\n%s\n' "${KRISP_PAGE2_JSON}" '200'
        ;;
      *)
        printf '%s\n%s\n' "${KRISP_PAGE1_JSON}" '200'
        ;;
    esac
  }

  run terminator::krisp::list --since 2026-07-01

  assert_success
  # Both pages contribute a row.
  assert_output --partial '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  Design review'
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
  # Unbounded pages request 100 at a time until the cursor runs out.
  grep -q -- 'limit=100' "${query_log}"
  grep -q -- 'from=2026-07-01' "${query_log}"
  grep -q -- 'cursor=page2' "${query_log}"
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list --since with --limit caps the range" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'cursor=page2'*)
        printf '%s\n%s\n' "${KRISP_PAGE2_JSON}" '200'
        ;;
      *)
        printf '%s\n%s\n' "${KRISP_PAGE1_JSON}" '200'
        ;;
    esac
  }

  run terminator::krisp::list --since 2026-07-01 --limit 1

  assert_success
  assert_output --partial '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  Design review'
  refute_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  Weekly sync'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list rejects a non-numeric limit" {
  _krisp_env

  run terminator::krisp::list --limit lots

  assert_failure
  assert_output --partial 'invalid limit'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list reports a curl failure" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl { return 7; }

  run terminator::krisp::list

  assert_failure
  assert_output --partial 'krisp request failed'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list reports an HTTP error" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl { printf '%s\n%s\n' '{"error":"Invalid API key"}' '401'; }

  run terminator::krisp::list

  assert_failure
  assert_output --partial 'HTTP 401'
}

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list reports none when there are no meetings" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl { printf '%s\n%s\n' "${KRISP_EMPTY_LIST_JSON}" '200'; }

  run terminator::krisp::list

  assert_success
  assert_output --partial '(no meetings)'
}

################################################################################
# terminator::krisp::get (mocked curl)
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get with no arg targets the most recent meeting" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  grep -q 'walking through the mockups' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  # The older Weekly sync meeting must not be fetched.
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get formats names, fallbacks, and hour rollover" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local entry="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qx 'id: aabbccddeeff00112233445566778899' "${entry}"
  grep -qx 'started_at: 2026-07-10T09:30:00Z' "${entry}"
  grep -qx 'duration: 1h 0m 0s' "${entry}"
  # Full name from the speakers map.
  grep -q 'Casey Rivera \[00:00:05\]: lets get started' "${entry}"
  # No name -> email fallback.
  grep -q 'sam@example.com \[00:00:11\]: sounds good' "${entry}"
  # Absent from the speakers map -> generic label.
  grep -q 'Speaker 3 \[00:01:00\]: unidentified voice' "${entry}"
  # Past one hour -> hh:mm:ss rolls over.
  grep -q 'Casey Rivera \[01:02:05\]: wrapping up' "${entry}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get resolves a unique prefix via the live list" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get 99887766

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  grep -q 'walking through the mockups' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get serves a cached prefix without any API call" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # Any curl invocation fails the test: the cache must serve offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get serves a cached prefix with KRISP_API_KEY unset" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  unset KRISP_API_KEY

  # Any curl invocation fails the test: the cache must serve fully offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get reports an ambiguous cached prefix without the key" {
  _krisp_env
  _seed_cache '{"id":"aabb111111111111111111111111111111"}'
  _seed_cache '{"id":"aabb222222222222222222222222222222"}'
  unset KRISP_API_KEY

  run terminator::krisp::get aabb

  assert_failure
  assert_output --partial "ambiguous meeting prefix 'aabb'"
  assert_output --partial 'aabb111111111111111111111111111111'
  assert_output --partial 'aabb222222222222222222222222222222'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get reports a corrupt entry when the cache file is unreadable" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  chmod 000 "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  unset KRISP_API_KEY

  # Any curl invocation fails the test: a corrupt entry must never fetch.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get aabbccdd

  chmod 644 "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  assert_failure
  assert_output --partial "cache entry for 'aabbccddeeff00112233445566778899' is corrupt"
  assert_output --partial 're-fetch with --refresh'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get with an unmatched prefix and no key asks for the key" {
  _krisp_env
  unset KRISP_API_KEY

  run terminator::krisp::get ffffffff

  assert_failure
  assert_output --partial 'KRISP_API_KEY is not set'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects an ambiguous live prefix" {
  _krisp_env

  # Nothing cached: the ambiguity must be resolved from the live list.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n%s\n' '{"meetings":[{"id":"cafe1111111111111111111111111111111","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"},{"id":"cafe2222222222222222222222222222222","title":"Design review","started_at":"2026-07-11T14:00:00Z","duration":1800,"status":"ready"}],"next_cursor":null,"total":2}' '200'
  }

  run terminator::krisp::get cafe

  assert_failure
  assert_output --partial "ambiguous meeting prefix 'cafe'"
  # Both candidates are listed to disambiguate.
  assert_output --partial 'cafe1111111111111111111111111111111'
  assert_output --partial 'cafe2222222222222222222222222222222'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects an unmatched prefix" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get ffffffff

  assert_failure
  assert_output --partial "no meeting matches 'ffffffff'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --json prints the raw response" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get --json aabbccdd

  assert_success
  assert_output --partial '"segments"'
  assert_output --partial '"lets get started"'
  # --json never writes the cache.
  [[ -z "$(ls -A "${TERMINATOR_KRISP_CACHE_DIR}")" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --refresh rewrites the lexical entry and removes the stale one" {
  _krisp_env
  # A stale entry under a different lexical name (no started_at -> epoch).
  _seed_cache '{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","transcript":{"language":"en","speakers":{},"segments":[{"speaker":0,"text":"old cached line","start":0,"end":1}]}}'
  _krisp_curl_ok

  run terminator::krisp::get --refresh aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The fresh entry lands under its proper lexical name and the stale
  # same-id entry is removed.
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  (($(grep -c 'old cached line' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}") == 0))
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/1970-01-01T00-00-00Z__aabbccddeeff00112233445566778899__Weekly-sync.md" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get 409 reports processing and never caches" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_LIST_JSON}" '200'
        ;;
      *'/meetings/'*)
        printf '%s\n%s\n' "${KRISP_409_JSON}" '409'
        ;;
    esac
  }

  run terminator::krisp::get

  assert_failure
  assert_output --partial 'still processing'
  assert_output --partial 'try again shortly'
  refute_output --partial 'lets get started'
  # Nothing was written to the cache.
  [[ -z "$(ls -A "${TERMINATOR_KRISP_CACHE_DIR}")" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get writes the cache atomically" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # No tmp file left behind by the tmp+mv write.
  [[ -z "$(find "${TERMINATOR_KRISP_CACHE_DIR}" -name '*.tmp*')" ]]
  # The cached entry is the rendered markdown under its lexical name.
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
  sed -n '1p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" | grep -qx -- '---'
  sed -n '2p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" | grep -qx 'doc_type: transcript'
  sed -n '3p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" | grep -qx 'id: aabbccddeeff00112233445566778899'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get does not cache an empty transcript" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_LIST_JSON}" '200'
        ;;
      *'/meetings/'*)
        printf '%s\n%s\n' "${KRISP_EMPTY_TRANSCRIPT_JSON}" '200'
        ;;
    esac
  }

  run terminator::krisp::get

  assert_failure
  assert_output --partial 'no transcript in response'
  # Nothing was written to the cache.
  [[ -z "$(ls -A "${TERMINATOR_KRISP_CACHE_DIR}")" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get does not glob-escape a prefix containing a slash" {
  _krisp_env
  _krisp_curl_ok
  mkdir -p "${TERMINATOR_KRISP_CACHE_DIR}/sub"
  printf '%s\n' 'not markdown' >"${TERMINATOR_KRISP_CACHE_DIR}/sub/2026-07-10T09-30-00Z__deadbeefdeadbeefdeadbeefdeadbeef__Dead.md"

  run terminator::krisp::get 'sub/deadbeef'

  assert_failure
  assert_output --partial "no meeting matches 'sub/deadbeef'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get matches cache prefixes literally, not as globs" {
  _krisp_env
  _krisp_curl_ok
  _seed_cache "${KRISP_MEETING_JSON}"

  # The glob quotes the token, so '?' stays literal and matches no cached
  # file; 'aabb?cdd' is also not a literal prefix of the cached id.
  run terminator::krisp::get 'aabb?cdd'

  assert_failure
  assert_output --partial "no meeting matches 'aabb?cdd'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get fails when the cache write fails" {
  _krisp_env
  _krisp_curl_ok
  chmod 500 "${TERMINATOR_KRISP_CACHE_DIR}"

  run terminator::krisp::get aabbccdd

  chmod 700 "${TERMINATOR_KRISP_CACHE_DIR}"
  assert_failure
  assert_output --partial 'failed to write cache entry'
  refute_output --partial 'lets get started'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get reports a corrupt cache entry cleanly" {
  _krisp_env
  printf 'not markdown\n' >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # Any curl invocation fails the test: a corrupt entry must never fetch.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get aabbccdd

  assert_failure
  assert_output --partial "cache entry for 'aabbccddeeff00112233445566778899' is corrupt"
  assert_output --partial 're-fetch with --refresh'
  refute_output --partial 'parse error'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get serves a frontmatter cache entry as-is" {
  _krisp_env

  # Any curl invocation fails the test: the cache must serve fully offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'duration: 1h 0m 0s' \
    'language: en' \
    '---' \
    '' \
    '# Weekly sync' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The entry is served byte-unchanged, not re-rendered.
  grep -qx 'Casey Rivera \[00:00:05\]: lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  sed -n '1p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" | grep -qx -- '---'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get serves a legacy two-line-header cache entry as-is" {
  _krisp_env

  # Any curl invocation fails the test: the cache must serve fully offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  # The real pre-frontmatter shape: current filename, old two-line header.
  printf '%s\n' \
    '# Weekly sync' \
    '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The entry is served byte-unchanged, not upgraded.
  grep -qx '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get treats a wrong-id frontmatter entry as corrupt" {
  _krisp_env

  # Any curl invocation fails the test: a corrupt entry must never fetch.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: 99887766554433221100ffeeddccbbaa' \
    'title: "Design review"' \
    '---' \
    '' \
    '# Design review' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  run terminator::krisp::get aabbccdd

  assert_failure
  assert_output --partial "cache entry for 'aabbccddeeff00112233445566778899' is corrupt"
  assert_output --partial 're-fetch with --refresh'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get serves a cached prefix without jq" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists {
    [[ "$1" == 'jq' ]] && return 1
    return 0
  }

  # Any curl invocation fails the test: the cache must serve fully offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qx 'id: aabbccddeeff00112233445566778899' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'Casey Rivera \[00:00:05\]: lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get -h shows usage" {
  run terminator::krisp::get -h

  assert_success
  assert_output --partial 'Usage: krisp-get'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects a second positional argument" {
  _krisp_env

  run terminator::krisp::get aabbccdd extra

  assert_failure
  assert_output --partial 'unexpected argument'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get -q is an unknown option" {
  _krisp_env

  run terminator::krisp::get -q aabbccdd

  assert_failure
  assert_output --partial "unknown option: '-q'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects a value-taking flag with no value" {
  _krisp_env

  run terminator::krisp::get --tag
  assert_failure
  assert_output --partial '--tag requires a tag value'

  run terminator::krisp::get -t
  assert_failure
  assert_output --partial '--tag requires a tag value'

  run terminator::krisp::get --since
  assert_failure
  assert_output --partial '--since requires a date'

  run terminator::krisp::get --until
  assert_failure
  assert_output --partial '--until requires a date'

  run terminator::krisp::get --on
  assert_failure
  assert_output --partial '--on requires a date'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects a prefix combined with --on" {
  _krisp_env

  run terminator::krisp::get aabbccdd --on 2026-07-10

  assert_failure
  assert_output --partial 'exclusive addressing forms'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects --on combined with --since" {
  _krisp_env

  run terminator::krisp::get --on 2026-07-10 --since 2026-07-10

  assert_failure
  assert_output --partial 'exclusive addressing forms'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --json with --on is contradictory" {
  _krisp_env

  run terminator::krisp::get --json --on 2026-07-10

  assert_failure
  assert_output --partial 'contradictory'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --json with --refresh is contradictory" {
  _krisp_env

  run terminator::krisp::get --json --refresh aabbccdd

  assert_failure
  assert_output --partial 'contradictory'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --json with --tag is contradictory" {
  _krisp_env

  run terminator::krisp::get --json --tag work aabbccdd

  assert_failure
  assert_output --partial 'contradictory'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects a calendar-invalid --on date" {
  _krisp_env

  run terminator::krisp::get --on 2026-02-30

  assert_failure
  assert_output --partial "invalid date: '2026-02-30'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects a malformed --since date" {
  _krisp_env

  run terminator::krisp::get --since 2026-13-01

  assert_failure
  assert_output --partial "invalid date: '2026-13-01'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects an invalid --tag value" {
  _krisp_env

  run terminator::krisp::get --tag 'has space' aabbccdd

  assert_failure
  assert_output --partial "invalid tag 'has space'"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --json with a cached prefix still fetches live" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # The live detail returns a different body than the cached entry.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    printf '%s\n%s\n' "${KRISP_MEETING2_JSON}" '200'
  }

  run terminator::krisp::get --json aabbccdd

  assert_success
  assert_output --partial 'walking through the mockups'
  refute_output --partial 'lets get started'
  # The cached entry was not rewritten with the live body.
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --tag on a cached entry retags in place" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # Any curl invocation fails the test: a cached --tag stays offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get --tag work aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # -t is the --tag shorthand; the retag is idempotent.
  run terminator::krisp::get -t work aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --tag on a miss renders the fetch with the tag" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get --tag work aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get bare with --tag targets the most recent meeting" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get --tag work

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --refresh preserves existing tags" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'client'
  _krisp_curl_ok

  run terminator::krisp::get --refresh aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The refetched entry keeps its tag and gains the fresh content.
  grep -qxF 'tags: [client]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --refresh --tag merges with existing tags" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'client'
  _krisp_curl_ok

  run terminator::krisp::get --refresh --tag work aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [client, work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --refresh refuses an entry with a malformed tags line" {
  _krisp_env
  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'tags: [bad tag!]' \
    '---' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  _krisp_curl_ok

  run terminator::krisp::get --refresh aabbccdd

  assert_failure
  assert_output --partial "cannot refresh '${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}'"
  assert_output --partial 'tags line is unreadable or malformed'
  # No fetch happened: the seeded bytes survive the refused refresh.
  grep -qxF 'tags: [bad tag!]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --refresh recovers an unreadable entry" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  chmod 000 "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  _krisp_curl_ok

  run terminator::krisp::get --refresh aabbccdd

  chmod 644 "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The refetch replaced the unreadable bytes with a valid entry.
  grep -q 'id: aabbccddeeff00112233445566778899' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --refresh recovers a truncated entry" {
  _krisp_env
  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  _krisp_curl_ok

  run terminator::krisp::get --refresh aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'id: aabbccddeeff00112233445566778899' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# One day: Weekly sync (ready, 09:30) plus Retro (processing, 16:00), newest
# first as the API returns them. Used by the range-pull tests.
KRISP_DAY_JSON='{"meetings":[{"id":"5566778899aabbccddeeff0011223344","title":"Retro","started_at":"2026-07-10T16:00:00Z","duration":900,"status":"processing"},{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"}],"next_cursor":null,"total":2}'

# The day plus a ready next-day meeting, newest first, as an API whose to
# bound includes the whole to-day returns them for from=D&to=D+1. The spill
# meeting has no mocked detail endpoint, so a test that lets it through fails
# on an unexpected curl call. Used by the strict-range tests.
KRISP_SPILL_JSON='{"meetings":[{"id":"00112233445566778899aabbccddeeff","title":"Next day standup","started_at":"2026-07-11T09:00:00Z","duration":600,"status":"ready"},{"id":"5566778899aabbccddeeff0011223344","title":"Retro","started_at":"2026-07-10T16:00:00Z","duration":900,"status":"processing"},{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"}],"next_cursor":null,"total":3}'

# Mocks the single-day API: the day list plus the Weekly sync detail. Every
# curl invocation is appended to KRISP_QUERY_LOG when the test sets it; any
# other call fails the test.
_krisp_curl_day() {
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    [[ -n "${KRISP_QUERY_LOG:-}" ]] && echo "$*" >>"${KRISP_QUERY_LOG}"
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_DAY_JSON}" '200'
        ;;
      *'/meetings/aabbccddeeff00112233445566778899'*)
        printf '%s\n%s\n' "${KRISP_MEETING_JSON}" '200'
        ;;
      *)
        echo "unexpected curl call: $*" >&2
        return 1
        ;;
    esac
  }
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on pulls a day, skipping still-processing meetings" {
  _krisp_env
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # --on maps to from=D&to=D+1.
  grep -q 'from=2026-07-10&to=2026-07-11' "${KRISP_QUERY_LOG}"
  # The ready meeting was fetched once; the processing one never was.
  (($(grep -c '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}") == 1))
  (($(grep -c '/meetings/5566778899aabbccddeeff0011223344' "${KRISP_QUERY_LOG}") == 0))
  # The skip is a stderr notice naming the meeting, not a failure.
  grep -q "skipped 'Retro'" <<<"${stderr}"
  grep -q 'transcription still processing' <<<"${stderr}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on is incremental on a second run" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # Only the list call happened: no detail fetches for the cached entry.
  (($(grep -c '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}") == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on --refresh refetches cached entries" {
  _krisp_env
  _seed_cache '{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready","transcript":{"language":"en","speakers":{},"segments":[{"speaker":0,"text":"old cached line","start":0,"end":1}]}}'
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10 --refresh

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}"
  (($(grep -c 'old cached line' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}") == 0))
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on --refresh preserves an existing tag" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" work
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10 --refresh

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The refetch happened, and the tags line survived it.
  grep -q '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on --refresh skips a malformed-tags entry without overwriting it" {
  _krisp_env
  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: aabbccddeeff00112233445566778899' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    'tags: [bad tag!]' \
    '---' \
    '' \
    'Casey Rivera [00:00:05]: lets get started' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10 --refresh

  assert_failure
  assert_output ''
  # The skip is a stderr notice naming the entry, and the refetch never
  # happened: the seeded bytes survive it.
  grep -q "skipped '${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}'" <<<"${stderr}"
  grep -q 'tags line is unreadable or malformed' <<<"${stderr}"
  (($(grep -c '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}") == 0))
  grep -qxF 'tags: [bad tag!]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on --refresh recovers a truncated entry" {
  _krisp_env
  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'title: "Weekly sync"' \
    'started_at: 2026-07-10T09:30:00Z' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10 --refresh

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The truncated entry was refetched and replaced with a valid one.
  (($(grep -c '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}") == 1))
  grep -q 'id: aabbccddeeff00112233445566778899' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on --refresh serves a cached copy when the API regressed to processing" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  query_log="$(mktemp)"

  # The list reports the cached Weekly sync as still processing.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "$*" >>"${query_log}"
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' '{"meetings":[{"id":"5566778899aabbccddeeff0011223344","title":"Retro","started_at":"2026-07-10T16:00:00Z","duration":900,"status":"processing"},{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"processing"}],"next_cursor":null,"total":2}' '200'
        ;;
      *)
        echo "unexpected curl call: $*" >&2
        return 1
        ;;
    esac
  }

  run --separate-stderr terminator::krisp::get --on 2026-07-10 --refresh

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The cached copy serves; the notice explains why.
  grep -q "serving cached 'Weekly sync'" <<<"${stderr}"
  (($(grep -c '/meetings/aabbccddeeff00112233445566778899' "${query_log}") == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range pulls union in an API-absent cached entry" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # The list no longer includes the cached Weekly sync.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_EMPTY_LIST_JSON}" '200'
        ;;
      *)
        echo "unexpected curl call: $*" >&2
        return 1
        ;;
    esac
  }

  run terminator::krisp::get --on 2026-07-10

  assert_success
  # The cache is the library source of truth: the entry still prints.
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range --refresh keeps an API-absent cached entry" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_EMPTY_LIST_JSON}" '200'
        ;;
      *)
        echo "unexpected curl call: $*" >&2
        return 1
        ;;
    esac
  }

  run terminator::krisp::get --on 2026-07-10 --refresh

  assert_success
  # Refetch is impossible; the cached copy is the entry and stays.
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range with an empty day prints nothing and exits 0" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_EMPTY_LIST_JSON}" '200'
        ;;
      *)
        echo "unexpected curl call: $*" >&2
        return 1
        ;;
    esac
  }

  run terminator::krisp::get --on 2026-07-10

  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range skips a 409 on fetch without failing" {
  _krisp_env

  # The status changed between list and fetch.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_DAY_JSON}" '200'
        ;;
      *'/meetings/'*)
        printf '%s\n%s\n' "${KRISP_409_JSON}" '409'
        ;;
    esac
  }

  run --separate-stderr terminator::krisp::get --on 2026-07-10

  assert_success
  assert_output ''
  grep -q "skipped 'Weekly sync'" <<<"${stderr}"
  grep -q 'transcription still processing' <<<"${stderr}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range reports one HTTP failure and still pulls the rest" {
  _krisp_env

  # Two ready meetings in range; only the Weekly sync detail succeeds.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' '{"meetings":[{"id":"99887766554433221100ffeeddccbbaa","title":"Design review","started_at":"2026-07-10T15:00:00Z","duration":1800,"status":"ready"},{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"}],"next_cursor":null,"total":2}' '200'
        ;;
      *'/meetings/aabbccddeeff00112233445566778899'*)
        printf '%s\n%s\n' "${KRISP_MEETING_JSON}" '200'
        ;;
      *'/meetings/'*)
        printf '%s\n%s\n' '{"error":"boom"}' '500'
        ;;
    esac
  }

  run --separate-stderr terminator::krisp::get --on 2026-07-10

  assert_failure
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q "skipped 'Design review'" <<<"${stderr}"
  grep -q 'HTTP 500' <<<"${stderr}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range excludes a corrupt cached entry and fails" {
  _krisp_env
  printf 'not markdown\n' >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10

  assert_failure
  assert_output ''
  grep -q "skipped '${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}': cache entry is corrupt" <<<"${stderr}"
  # A corrupt entry is never silently re-fetched.
  (($(grep -c '/meetings/aabbccddeeff00112233445566778899' "${KRISP_QUERY_LOG}") == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get range --tag tags cached and fetched entries alike" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # The cached Weekly sync plus a fresh Design review, newest first.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' '{"meetings":[{"id":"99887766554433221100ffeeddccbbaa","title":"Design review","started_at":"2026-07-11T14:00:00Z","duration":1800,"status":"ready"},{"id":"aabbccddeeff00112233445566778899","title":"Weekly sync","started_at":"2026-07-10T09:30:00Z","duration":3600,"status":"ready"}],"next_cursor":null,"total":2}' '200'
        ;;
      *'/meetings/aabbccddeeff00112233445566778899'*)
        printf '%s\n%s\n' "${KRISP_MEETING_JSON}" '200'
        ;;
      *'/meetings/99887766554433221100ffeeddccbbaa'*)
        printf '%s\n%s\n' "${KRISP_MEETING2_JSON}" '200'
        ;;
    esac
  }

  run terminator::krisp::get --since 2026-07-10 --until 2026-07-12 --tag work

  assert_success
  # Oldest first, regardless of the API's newest-first order.
  assert_line --index 0 "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  assert_line --index 1 "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --on excludes the next day despite the inclusive API to bound" {
  _krisp_env
  KRISP_DAY_JSON="${KRISP_SPILL_JSON}"
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --on 2026-07-10

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The query still spans both days; the next-day meeting is filtered out
  # client-side and never fetched.
  grep -q 'from=2026-07-10&to=2026-07-11' "${KRISP_QUERY_LOG}"
  (($(grep -c '/meetings/00112233445566778899aabbccddeeff' "${KRISP_QUERY_LOG}") == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --until is exclusive of the until day" {
  _krisp_env
  KRISP_DAY_JSON="${KRISP_SPILL_JSON}"
  KRISP_QUERY_LOG="$(mktemp)"
  _krisp_curl_day

  run --separate-stderr terminator::krisp::get --until 2026-07-10

  assert_success
  # Everything in the mock is on 2026-07-10 or later: nothing is in range,
  # so nothing prints and only the list call happened.
  assert_output ''
  (($(grep -c '' "${KRISP_QUERY_LOG}") == 1))
  grep -q 'to=2026-07-10' "${KRISP_QUERY_LOG}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get --since --until keeps strict bounds" {
  _krisp_env
  local log
  log="$(mktemp)"

  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "$*" >>"${log}"
    case "$*" in
      *'/meetings?'*)
        printf '%s\n%s\n' "${KRISP_EMPTY_LIST_JSON}" '200'
        ;;
    esac
  }

  run terminator::krisp::get --since 2026-07-10 --until 2026-07-11

  assert_success
  assert_output ''
  grep -q 'from=2026-07-10&to=2026-07-11' "${log}"
}

################################################################################
# terminator::krisp::cache
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache lists entries oldest first with sizes" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::cache

  assert_success
  assert_line --index 0 "Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}"
  assert_line --index 1 --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899'
  assert_line --index 1 --partial 'Weekly-sync'
  assert_line --index 2 --partial '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa'
  assert_line --index 2 --partial 'Design-review'
  assert_line --index 3 --partial '2 transcripts,'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "__human_size__ formats bytes, K, and M" {
  run terminator::krisp::__human_size__ 512

  assert_success
  assert_output '512B'

  run terminator::krisp::__human_size__ 1536

  assert_success
  assert_output '1.5K'

  run terminator::krisp::__human_size__ $((5 * 1048576 + 512 * 1024))

  assert_success
  assert_output '5.5M'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "__color_auto__ stays off when piped, NO_COLOR, or TERM=dumb" {
  # bats captures stdout through a pipe, so the terminal check is false here.
  run terminator::krisp::__color_auto__

  assert_failure

  NO_COLOR=1
  run terminator::krisp::__color_auto__

  assert_failure

  TERM=dumb
  run terminator::krisp::__color_auto__

  assert_failure
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "__tag_token__ renders plain and colored tokens" {
  local token esc=$'\033'

  run terminator::krisp::__tag_token__ 'work, team' 0

  assert_success
  assert_output '[work, team]'

  run terminator::krisp::__tag_token__ 'work, team' 1

  assert_success
  assert_output "${esc}[36m[work, team]${esc}[0m"

  terminator::krisp::__tag_token__ 'work' 1 token
  [[ "${token}" == "${esc}[36m[work]${esc}[0m" ]]

  TERMINATOR_KRISP_TAG_COLOR_CODE='38;5;69m'
  run terminator::krisp::__tag_token__ 'work' 1

  assert_success
  assert_output "${esc}[38;5;69m[work]${esc}[0m"

  TERMINATOR_KRISP_TAG_COLOR="${esc}[35m"
  run terminator::krisp::__tag_token__ 'work' 1

  assert_success
  assert_output "${esc}[35m[work]${esc}[0m"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache_view_rows
@test "__cache_view_rows__ renders the view's rows without header or footer" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}"

  local selection
  selection="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}
${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  local view
  view="$(terminator::krisp::__cache_view__ "${selection}")"
  run terminator::krisp::__cache_view_rows__ "${selection}"

  assert_success
  # Exactly the view's middle lines: no cache-dir header, no count footer.
  assert_output "$(printf '%s\n' "${view}" | sed '1d;$d')"

  # An empty selection renders nothing at all.
  run terminator::krisp::__cache_view_rows__ ''

  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::pick_entries
@test "__pick_entries__ resolves marked rows back to cache paths" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}"

  # fzf echoes the marked rows back, the second entry first.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n%s\n' \
      '2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  1.2K  Design-review' \
      '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  1.2K  [work]  Weekly-sync'
  }

  local selection picked
  selection="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}
${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
  terminator::krisp::__pick_entries__ picked "${selection}"

  [[ "${picked}" == "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}
${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::pick_entries
@test "__pick_entries__ cancels on empty output and nonzero fzf exits" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  local selection="${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  local picked

  # An accept with nothing marked prints nothing.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf { cat >/dev/null; }
  picked='sentinel'
  if terminator::krisp::__pick_entries__ picked "${selection}"; then
    fail 'expected empty output to cancel'
  fi
  [[ "${picked}" == '' ]]

  # Esc aborts with status 130; the marked rows are discarded.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n' '2026-07-10T09:30Z  aabbccddeeff00112233445566778899  1.2K  [work]  Weekly-sync'
    return 130
  }
  picked='sentinel'
  if terminator::krisp::__pick_entries__ picked "${selection}"; then
    fail 'expected a nonzero fzf exit to cancel'
  fi
  [[ "${picked}" == '' ]]

  # A row whose id resolves to no cache entry cancels the whole pick.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n' '2026-07-10T09:30Z  ffffffffffffffffffffffffffffffff  1.2K  Nowhere'
  }
  picked='sentinel'
  if terminator::krisp::__pick_entries__ picked "${selection}"; then
    fail 'expected an unresolvable id to cancel'
  fi
  [[ "${picked}" == '' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::pick_tags
@test "__pick_tags__ parses the query line and marked tags into one list" {
  _krisp_env

  # Line 1 is the query, the rest are marked tags; duplicates collapse
  # keeping their first occurrence.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n%s\n%s\n' 'work, extra' 'team' 'work'
  }
  local picked='sentinel'
  terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'
  [[ "${picked}" == 'work, extra, team' ]]

  # Queries split on bare spaces as well as commas.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n%s\n' 'work extra' 'team'
  }
  picked='sentinel'
  terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'
  [[ "${picked}" == 'work, extra, team' ]]

  # An empty query line with marked tags works.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n%s\n' '' 'team'
  }
  picked='sentinel'
  terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'
  [[ "${picked}" == 'team' ]]

  # An accept with no query and nothing marked gives zero tags.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '\n'
  }
  picked='sentinel'
  terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'
  [[ "${picked}" == '' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::pick_tags
@test "__pick_tags__ cancels on esc and rejects invalid tokens" {
  _krisp_env

  # Esc aborts with status 130; the query line is discarded.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n' 'work'
    return 130
  }
  local picked='sentinel'
  if terminator::krisp::__pick_tags__ picked 'work' 'pick tags'; then
    fail 'expected a nonzero fzf exit to cancel'
  fi
  [[ "${picked}" == '' ]]

  # An invalid token is rejected before any mutation, naming it.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n' 'work -bad'
  }
  run terminator::krisp::__pick_tags__ picked 'work' 'pick tags'

  assert_failure 2
  assert_output --partial "krisp: invalid tag '-bad'"
}

# bats test_tags=terminator::krisp,terminator::krisp::pick_tags
@test "__pick_tags__ accepts a typed no-match query on fzf exit 1" {
  _krisp_env

  # Enter with no match exits 1 printing the typed query: the query is the
  # typed-tag accept, nothing is marked.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n' 'brand-new'
    return 1
  }
  local picked='sentinel'
  terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'
  [[ "${picked}" == 'brand-new' ]]

  # A comma-joined typed query splits like a marked one.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '%s\n' 'work, brand-new'
    return 1
  }
  picked='sentinel'
  terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'
  [[ "${picked}" == 'work, brand-new' ]]

  # An empty query on exit 1 is a cancel.
  # shellcheck disable=SC2317 # invoked indirectly
  function fzf {
    cat >/dev/null
    printf '\n'
    return 1
  }
  picked='sentinel'
  if terminator::krisp::__pick_tags__ picked 'work
team' 'pick tags'; then
    fail 'expected an empty typed query on fzf exit 1 to cancel'
  fi
  [[ "${picked}" == '' ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache migrates a legacy .json entry on view" {
  _krisp_env
  printf '%s\n' "${KRISP_MEETING_JSON}" >"${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json"

  run terminator::krisp::cache

  assert_success
  assert_output --partial 'Migrated 1 legacy cache entry'
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json" ]]
  grep -q 'Casey Rivera \[00:00:05\]: lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache drops a legacy entry superseded by a lexical entry" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  printf '%s\n' "${KRISP_MEETING_JSON}" >"${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json"

  run terminator::krisp::cache

  assert_success
  refute_output --partial 'Migrated'
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json" ]]
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache warns and skips migration when jq is missing" {
  _krisp_env
  printf '%s\n' "${KRISP_MEETING_JSON}" >"${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json"

  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists {
    [[ "$1" == 'jq' ]] && return 1
    return 0
  }

  run terminator::krisp::cache

  assert_success
  assert_output --partial 'skipping legacy cache migration'
  # The legacy entry is left in place.
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache renames old-grammar entries on view" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  mv "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" \
    "${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md"

  run terminator::krisp::cache

  assert_success
  assert_output --partial 'Migrated 1 cache filename(s) to the current grammar'
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md" ]]
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
  # Header line 2 is rebuilt as full ISO from the filename.
  sed -n '2p' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" \
    | grep -qx '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)'
  # The listing shows the migrated entry under its new timestamp.
  assert_output --partial '2026-07-10T09:30Z  aabbccddeeff00112233445566778899'

  # The migrated entry serves fully offline.
  unset KRISP_API_KEY
  run terminator::krisp::get aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache name migration is idempotent" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache

  assert_success
  refute_output --partial 'Migrated'
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache drops an old-grammar entry superseded by a current one" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  printf '%s\n' 'stale' >"${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md"

  run terminator::krisp::cache

  assert_success
  refute_output --partial 'Migrated'
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md" ]]
  # The current-grammar entry's content wins.
  grep -q 'Casey Rivera' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache leaves non-grammar markdown files alone" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  printf '%s\n' 'notes' >"${TERMINATOR_KRISP_CACHE_DIR}/notes.md"
  printf '%s\n' 'two segments' >"${TERMINATOR_KRISP_CACHE_DIR}/a_b.md"
  printf '%s\n' 'four segments' >"${TERMINATOR_KRISP_CACHE_DIR}/a_b_c_d.md"

  run terminator::krisp::cache

  assert_success
  refute_output --partial 'Migrated'
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/notes.md" ]]
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/a_b.md" ]]
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/a_b_c_d.md" ]]
  # Malformed names are not listed.
  refute_output --partial 'a_b.md'
  refute_output --partial 'a_b_c_d.md'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --rm migrates an old-grammar entry before removing it" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  mv "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" \
    "${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md"

  run terminator::krisp::cache --rm aabbccdd

  assert_success
  assert_output --partial 'Migrated 1 cache filename(s) to the current grammar'
  assert_output --partial "Removed ${KRISP_MEETING_MD}"
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md" ]]
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "krisp-get --refresh removes an old-grammar same-id entry" {
  _krisp_env
  _krisp_curl_ok
  # An old-grammar entry with distinct stale content.
  printf '%s\n%s\n%s\n' '# Weekly sync' '2026-07-10 09:30 UTC (id aabbccddeeff00112233445566778899)' 'old cached line' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md"

  run terminator::krisp::get --refresh aabbccdd

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  (($(grep -c 'old cached line' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}") == 0))
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/2026-07-10T09-30-00_aabbccddeeff00112233445566778899_Weekly-sync.md" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache --rm removes a single entry by id prefix" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::cache --rm aabbccdd

  assert_success
  assert_output "Removed ${KRISP_MEETING_MD}"
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" ]]
  [[ -f "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache --rm rejects an ambiguous prefix" {
  _krisp_env
  _seed_cache '{"id":"aabb111111111111111111111111111111"}'
  _seed_cache '{"id":"aabb222222222222222222222222222222"}'

  run terminator::krisp::cache --rm aabb

  assert_failure
  assert_output --partial "ambiguous meeting prefix 'aabb'"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache --rm reports no match for slug-only prefixes" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache --rm Weekly

  assert_failure
  assert_output --partial "no cached transcript matches 'Weekly'"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache --rm requires a prefix" {
  _krisp_env

  run terminator::krisp::cache --rm

  assert_failure
  assert_output --partial 'requires a meeting id prefix'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache rejects a value-taking flag with no value" {
  _krisp_env

  run terminator::krisp::cache --since
  assert_failure
  assert_output --partial '--since requires a date'

  run terminator::krisp::cache --until
  assert_failure
  assert_output --partial '--until requires a date'

  run terminator::krisp::cache --on
  assert_failure
  assert_output --partial '--on requires a date'

  run terminator::krisp::cache --tag
  assert_failure
  assert_output --partial '--tag requires a tag value'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache --clear removes entries, tmp files, and legacy json" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"
  # Stale partial writes from interrupted cache writes, both formats.
  printf '%s\n' 'partial' >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}.tmp.999"
  printf '%s\n' 'partial' >"${TERMINATOR_KRISP_CACHE_DIR}/legacy0000000000000000000000000000.json.tmp.999"
  printf '%s\n' '{}' >"${TERMINATOR_KRISP_CACHE_DIR}/legacy0000000000000000000000000000.json"

  run terminator::krisp::cache --clear

  assert_success
  assert_output --partial 'Cleared 2'

  local \
    count=0 \
    entry
  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*.md "${TERMINATOR_KRISP_CACHE_DIR}"/*.md.tmp.* \
    "${TERMINATOR_KRISP_CACHE_DIR}"/*.json "${TERMINATOR_KRISP_CACHE_DIR}"/*.json.tmp.*; do
    [[ -f "${entry}" ]] && count=$((count + 1))
  done
  ((count == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache --clear on an empty cache reports zero" {
  _krisp_env

  run terminator::krisp::cache --clear

  assert_success
  assert_output --partial 'Cleared 0'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache -h shows usage" {
  run terminator::krisp::cache -h

  assert_success
  assert_output --partial 'Usage: krisp-cache'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache usage documents the color flags and their rules" {
  run terminator::krisp::cache -h

  assert_success
  assert_output --partial '--color'
  assert_output --partial '--no-color'
  assert_output --partial 'NO_COLOR'
  assert_output --partial 'TERMINATOR_KRISP_TAG_COLOR_CODE'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache view shows a tags token between size and slug" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}"

  local size1 size2
  size1="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")"
  size2="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}")"

  run terminator::krisp::cache

  assert_success
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  $(terminator::krisp::__human_size__ "${size1}")  [work]  Weekly-sync"
  # Untagged entries keep the line shape without the token.
  assert_line --index 2 "2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  $(terminator::krisp::__human_size__ "${size2}")  Design-review"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache view right-aligns the size column to the widest entry" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"
  # Grow one entry past 10K so its size renders a char wider than the
  # other's; the smaller one must pad so the columns after it line up.
  head -c 20480 /dev/zero | tr '\0' x >>"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  local size1 size2 human1 human2
  size1="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")"
  size2="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}")"
  terminator::krisp::__human_size__ "${size1}" human1
  terminator::krisp::__human_size__ "${size2}" human2

  run terminator::krisp::cache

  assert_success
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  $(printf '%*s' "${#human2}" "${human1}")  Weekly-sync"
  assert_line --index 2 "2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  ${human2}  Design-review"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --color colors the tags token and nothing else" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}"

  local size1 size2 human1 human2 esc=$'\033'
  size1="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")"
  size2="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}")"
  terminator::krisp::__human_size__ "${size1}" human1
  terminator::krisp::__human_size__ "${size2}" human2

  run terminator::krisp::cache --color

  assert_success
  # Only the tags token gains the escape bytes; every other line is unchanged.
  assert_line --index 0 "Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}"
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  ${human1}  ${esc}[36m[work]${esc}[0m  Weekly-sync"
  assert_line --index 2 "2026-07-11T14:00Z  99887766554433221100ffeeddccbbaa  ${human2}  Design-review"
  assert_line --index 3 "2 transcripts, $(terminator::krisp::__human_size__ $((size1 + size2))) total"

  # The forced flag also beats NO_COLOR.
  NO_COLOR=1
  run terminator::krisp::cache --color

  assert_success
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  ${human1}  ${esc}[36m[work]${esc}[0m  Weekly-sync"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache colors automatically when __color_auto__ reports a terminal" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  local size human esc=$'\033'
  size="$(wc -c <"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}")"
  terminator::krisp::__human_size__ "${size}" human

  # bats pipes stdout, so pretend the terminal check says yes.
  terminator::krisp::__color_auto__() { return 0; }

  run terminator::krisp::cache

  assert_success
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  ${human}  ${esc}[36m[work]${esc}[0m  Weekly-sync"

  # The auto color respects the env override.
  TERMINATOR_KRISP_TAG_COLOR_CODE='38;5;69m'
  run terminator::krisp::cache

  assert_success
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  ${human}  ${esc}[38;5;69m[work]${esc}[0m  Weekly-sync"

  # --no-color forces the token plain even when the check says yes.
  run terminator::krisp::cache --no-color

  assert_success
  assert_line --index 1 "2026-07-10T09:30Z  aabbccddeeff00112233445566778899  ${human}  [work]  Weekly-sync"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --color leaves --path output pure" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache --color --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --path prints absolute paths only, oldest first" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::cache --path

  assert_success
  assert_output "$(printf '%s\n%s' \
    "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" \
    "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}")"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --path on an empty cache prints nothing" {
  _krisp_env

  run terminator::krisp::cache --path

  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --path keeps migration notices off stdout" {
  _krisp_env
  printf '%s\n' "${KRISP_MEETING_JSON}" >"${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json"

  run --separate-stderr terminator::krisp::cache --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -q 'Migrated 1 legacy cache entry' <<<"${stderr}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --on filters both views to a single day" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::cache --on 2026-07-10

  assert_success
  assert_line --index 0 "Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}"
  assert_line --index 1 --partial 'aabbccddeeff00112233445566778899'
  assert_line --index 2 --partial '1 transcript,'
  refute_line --partial '99887766554433221100ffeeddccbbaa'

  run terminator::krisp::cache --on 2026-07-10 --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --since/--until bounds are strict" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::cache --since 2026-07-10 --path

  assert_success
  assert_output "$(printf '%s\n%s' \
    "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" \
    "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}")"

  run terminator::krisp::cache --until 2026-07-11 --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  run terminator::krisp::cache --since 2026-07-10 --until 2026-07-11 --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache date filters accept ISO timestamps" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache --since 2026-07-10T09:30:00Z --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  run terminator::krisp::cache --since 2026-07-10T09:30:01Z --path

  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --tag matches exactly, never as a substring" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}" 'workshop'

  run terminator::krisp::cache --tag work --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --tag matches any tag in a multi-tag entry" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'alpha, beta'

  run terminator::krisp::cache --tag beta --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache filter zero-match is a valid empty result" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache --tag nomatch --path

  assert_success
  assert_output ''

  # The filtered default view prints nothing: no header, no summary.
  run terminator::krisp::cache --on 2020-01-01

  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --rm and --clear are exclusive with --path and the filters" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache --rm aabbccdd --path

  assert_failure
  assert_output --partial 'exclusive with --path and the filters'

  run terminator::krisp::cache --clear --tag work

  assert_failure
  assert_output --partial 'exclusive with --path and the filters'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache --on is exclusive with --since and --until" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::cache --on 2026-07-10 --since 2026-07-10

  assert_failure
  assert_output --partial 'exclusive with --since and --until'

  run terminator::krisp::cache --on 2026-07-10 --until 2026-07-11

  assert_failure
  assert_output --partial 'exclusive with --since and --until'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache rejects invalid dates and tags" {
  _krisp_env

  run terminator::krisp::cache --on 2026-02-30

  assert_failure
  assert_output --partial "invalid date: '2026-02-30'"

  run terminator::krisp::cache --since not-a-date

  assert_failure
  assert_output --partial "invalid date: 'not-a-date'"

  run terminator::krisp::cache --tag 'bad tag!'

  assert_failure
  assert_output --partial "invalid tag 'bad tag!'"
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "krisp-cache view and filters work fully offline" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  unset KRISP_API_KEY

  run terminator::krisp::cache --tag work --path

  assert_success
  assert_output "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

################################################################################
# terminator::krisp::tag
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x adds tags to one entry by id prefix" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}"

  run terminator::krisp::tag -x team --id aabbccdd

  assert_success
  assert_output "Tagged 1 transcript with 'team'"
  grep -qxF 'tags: [team, work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  (($(grep -c 'tags:' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}") == 0))

  # Positional TAGs merge, deduped, into one comma-joined list.
  run terminator::krisp::tag -x review team --id aabbccdd

  assert_success
  assert_output "Tagged 1 transcript with 'review, team'"
  grep -qxF 'tags: [review, team, work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x rejects zero-match and ambiguous id prefixes" {
  _krisp_env
  _seed_cache '{"id":"aabb111111111111111111111111111111"}'
  _seed_cache '{"id":"aabb222222222222222222222222222222"}'

  run terminator::krisp::tag -x work --id aabb

  assert_failure
  assert_output --partial "ambiguous meeting prefix 'aabb'"

  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::tag -x work --id deadbeef

  assert_failure
  assert_output --partial "no cached transcript matches 'deadbeef'"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x applies the date and tag selectors" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}" 'team'

  # --on scopes to the single day.
  run terminator::krisp::tag -x review --on 2026-07-10

  assert_success
  assert_output "Tagged 1 transcript with 'review'"
  grep -qxF 'tags: [review, work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [team]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  # --since keeps the newer entry only.
  run terminator::krisp::tag -x retro --since 2026-07-11

  assert_success
  assert_output "Tagged 1 transcript with 'retro'"
  grep -qxF 'tags: [retro, team]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  # --tag narrows to entries carrying the tag.
  run terminator::krisp::tag -x sync --tag work

  assert_success
  assert_output "Tagged 1 transcript with 'sync'"
  grep -qxF 'tags: [review, sync, work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # The date bounds and --tag intersect.
  run terminator::krisp::tag -x daily --since 2026-07-10 --until 2026-07-12 --tag team

  assert_success
  assert_output "Tagged 1 transcript with 'daily'"
  grep -qxF 'tags: [daily, retro, team]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x --rm removes tags idempotently" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work, team'

  run terminator::krisp::tag -x --rm team --id aabbccdd

  assert_success
  assert_output "Removed 'team' from 1 transcript"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # An absent tag writes nothing: the summary still prints, bytes unchanged.
  local before
  before="$(mktemp)"
  cp "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}" "${before}"
  run terminator::krisp::tag -x --rm team --id aabbccdd

  assert_success
  assert_output "Removed 'team' from 1 transcript"
  cmp "${before}" "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"

  # Removing the last tag omits the tags line entirely.
  run terminator::krisp::tag -x --rm work --id aabbccdd

  assert_success
  assert_output "Removed 'work' from 1 transcript"
  (($(grep -c 'tags:' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}") == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x zero-match selector is an error" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  run terminator::krisp::tag -x work --on 2020-01-01

  assert_failure
  assert_output --partial 'no cached transcripts match the selector'
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x skips a malformed entry, reporting it" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  printf '%s\n' \
    '---' \
    'doc_type: transcript' \
    'id: 99887766554433221100ffeeddccbbaa' \
    'title: "Design review"' \
    'started_at: 2026-07-11T14:00:00Z' \
    'tags: [bad tag!]' \
    '---' \
    '' \
    'Dana Ng [00:00:03]: walking through the mockups' \
    >"${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  run terminator::krisp::tag -x review --since 2026-07-10 --until 2026-07-12

  assert_failure
  assert_output --partial "Tagged 1 transcript with 'review'"
  assert_output --partial "cannot retag '${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}'"
  grep -qxF 'tags: [review, work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  # The malformed entry is left untouched.
  grep -qxF 'tags: [bad tag!]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag -x requires tags and a selector" {
  _krisp_env

  run terminator::krisp::tag -x

  assert_failure
  assert_output --partial 'krisp-tag -x requires at least one TAG'

  run terminator::krisp::tag -x work

  assert_failure
  assert_output --partial 'krisp-tag -x requires a selector'

  run terminator::krisp::tag -x --rename

  assert_failure
  assert_output --partial 'krisp-tag -x with --rename requires OLD:NEW'
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag --rename renames library-wide with resorted tags" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'team, work'
  _seed_cache "${KRISP_MEETING2_JSON}" 'work'

  run terminator::krisp::tag --rename work:review

  assert_success
  assert_output "Renamed 'work' to 'review' in 2 transcripts"
  grep -qxF 'tags: [review, team]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [review]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"

  # A valued --rename picks nothing, so it runs under -x too.
  run terminator::krisp::tag -x --rename review:sync

  assert_success
  assert_output "Renamed 'review' to 'sync' in 2 transcripts"
  grep -qxF 'tags: [sync, team]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
  grep -qxF 'tags: [sync]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING2_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag --rename zero-match OLD is an error" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  run terminator::krisp::tag --rename nope:team

  assert_failure
  assert_output --partial "no cached transcript carries 'nope'"
  grep -qxF 'tags: [work]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag --rename is exclusive and validates its value" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  run terminator::krisp::tag --rename work:team extra

  assert_failure
  assert_output --partial 'krisp-tag --rename is exclusive with --rm, TAGs, and the selectors'

  run terminator::krisp::tag --rename work:team --rm

  assert_failure
  assert_output --partial 'krisp-tag --rename is exclusive with --rm, TAGs, and the selectors'

  run terminator::krisp::tag --rename work:team --on 2026-07-10

  assert_failure
  assert_output --partial 'krisp-tag --rename is exclusive with --rm, TAGs, and the selectors'

  run terminator::krisp::tag --rename :team

  assert_failure
  assert_output --partial "krisp-tag --rename expects OLD:NEW (got ':team')"

  run terminator::krisp::tag --rename work:

  assert_failure
  assert_output --partial "krisp-tag --rename expects OLD:NEW (got 'work:')"

  run terminator::krisp::tag --rename work:work

  assert_failure
  assert_output --partial "krisp-tag --rename expects OLD:NEW (got 'work:work')"
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag guards name -x/--exec when a picker would open" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  # fzf missing: the error names the non-interactive switch.
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::krisp::tag team --id aabbccdd

  assert_failure
  assert_output --partial 'krisp-tag requires fzf for its pickers; pass -x/--exec to run non-interactively'

  # stdin is not a terminal: the same switch is named.
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  run terminator::krisp::tag team --id aabbccdd </dev/null

  assert_failure
  assert_output --partial 'krisp-tag requires a terminal for its pickers; pass -x/--exec to run non-interactively'
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag interactive zero-match feeds are notices, not errors" {
  _krisp_env
  # A missing fzf proves no guard ever ran: the checks below never open a
  # picker.
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  # An empty cache is an empty pick list.
  run terminator::krisp::tag

  assert_success
  assert_output --partial 'no cached transcripts to tag'

  # A valueless --rename over an untagged library has nothing to offer.
  run terminator::krisp::tag --rename

  assert_success
  assert_output --partial 'the library carries no tags'

  # A selector matching nothing is the same empty list interactively.
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  run terminator::krisp::tag team --on 2020-01-01

  assert_success
  assert_output --partial 'no cached transcripts to tag'

  run terminator::krisp::tag --id deadbeef

  assert_success
  assert_output --partial 'no cached transcripts to tag'
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag rejects unknown options and invalid values" {
  _krisp_env

  run terminator::krisp::tag --bogus

  assert_failure
  assert_output --partial "krisp-tag unknown option: '--bogus'"

  run terminator::krisp::tag --id

  assert_failure
  assert_output --partial 'krisp-tag --id requires a meeting id prefix'

  run terminator::krisp::tag --tag

  assert_failure
  assert_output --partial 'krisp-tag --tag requires a tag value'

  run terminator::krisp::tag --id aabbccdd --on 2026-07-10

  assert_failure
  assert_output --partial 'krisp-tag --id is exclusive with --on, --since, --until, and --tag'

  run terminator::krisp::tag --on 2026-07-10 --since 2026-07-10

  assert_failure
  assert_output --partial 'krisp-tag --on is exclusive with --since and --until'

  run terminator::krisp::tag --on 2026-02-30

  assert_failure
  assert_output --partial "krisp-tag invalid date: '2026-02-30'"

  run terminator::krisp::tag --since not-a-date

  assert_failure
  assert_output --partial "krisp-tag invalid date: 'not-a-date'"

  run terminator::krisp::tag 'bad tag!'

  assert_failure
  assert_output --partial "krisp: invalid tag 'bad tag!'"

  run terminator::krisp::tag --tag 'bad tag!'

  assert_failure
  assert_output --partial "krisp: invalid tag 'bad tag!'"

  run terminator::krisp::tag -h

  assert_success
  assert_output --partial 'Usage: krisp-tag'
}

# bats test_tags=terminator::krisp,terminator::krisp::tag
@test "krisp-tag works fully offline with migration notices on stderr" {
  _krisp_env
  printf '%s\n' "${KRISP_MEETING_JSON}" >"${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json"
  unset KRISP_API_KEY

  run --separate-stderr terminator::krisp::tag -x team --id aabbccdd

  assert_success
  assert_output "Tagged 1 transcript with 'team'"
  grep -q 'Migrated 1 legacy cache entry' <<<"${stderr}"
  [[ ! -e "${TERMINATOR_KRISP_CACHE_DIR}/aabbccddeeff00112233445566778899.json" ]]
  grep -qxF 'tags: [team]' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

################################################################################
# terminator::krisp::__completion__
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers cached ids for krisp-get" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  COMP_WORDS=(krisp-get '')
  COMP_CWORD=1
  terminator::krisp::__completion__

  [[ " ${COMPREPLY[*]} " == *' aabbccddeeff00112233445566778899 '* ]]
  [[ " ${COMPREPLY[*]} " == *' 99887766554433221100ffeeddccbbaa '* ]]

  # -t takes a value, so the id PREFIX positional stays available after it.
  COMP_WORDS=(krisp-get -t work '')
  COMP_CWORD=3
  terminator::krisp::__completion__

  [[ " ${COMPREPLY[*]} " == *' aabbccddeeff00112233445566778899 '* ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ filters ids by prefix" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  COMP_WORDS=(krisp-get aabb)
  COMP_CWORD=1
  terminator::krisp::__completion__

  [[ " ${COMPREPLY[*]} " == *' aabbccddeeff00112233445566778899 '* ]]
  [[ " ${COMPREPLY[*]} " != *' 99887766554433221100ffeeddccbbaa '* ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers help flags on a dash" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  COMP_WORDS=(krisp-get -)
  COMP_CWORD=1
  terminator::krisp::__completion__

  [[ " ${COMPREPLY[*]} " == *' --help '* ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers each command's own flags on a dash" {
  _krisp_env

  COMP_WORDS=(krisp-get -)
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' --refresh '* ]]
  [[ " ${COMPREPLY[*]} " == *' --tag '* ]]
  [[ " ${COMPREPLY[*]} " == *' -t '* ]]
  [[ " ${COMPREPLY[*]} " != *' --quiet '* ]]

  COMP_WORDS=(krisp-cache -)
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' --rm '* ]]
  [[ " ${COMPREPLY[*]} " == *' --path '* ]]
  [[ " ${COMPREPLY[*]} " == *' --tag '* ]]
  [[ " ${COMPREPLY[*]} " == *' --color '* ]]
  [[ " ${COMPREPLY[*]} " == *' --no-color '* ]]
  [[ " ${COMPREPLY[*]} " != *' --add-tag '* ]]

  COMP_WORDS=(krisp-list -)
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' --limit '* ]]
  [[ " ${COMPREPLY[*]} " == *' --since '* ]]
  [[ " ${COMPREPLY[*]} " == *' --on '* ]]

  COMP_WORDS=(krisp-tag -)
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' -x '* ]]
  [[ " ${COMPREPLY[*]} " == *' --exec '* ]]
  [[ " ${COMPREPLY[*]} " == *' --rm '* ]]
  [[ " ${COMPREPLY[*]} " == *' --rename '* ]]
  [[ " ${COMPREPLY[*]} " == *' --id '* ]]
  [[ " ${COMPREPLY[*]} " == *' --on '* ]]
  [[ " ${COMPREPLY[*]} " == *' --since '* ]]
  [[ " ${COMPREPLY[*]} " == *' --until '* ]]
  [[ " ${COMPREPLY[*]} " == *' --tag '* ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers nothing past the first argument" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  COMP_WORDS=(krisp-get aabbccddeeff00112233445566778899 '')
  COMP_CWORD=2
  # A stale completion must be cleared, not left behind.
  COMPREPLY=('stale-id')
  terminator::krisp::__completion__

  ((${#COMPREPLY[@]} == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers no ids for krisp-list" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  COMP_WORDS=(krisp-list '')
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__

  ((${#COMPREPLY[@]} == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers no ids for krisp-get past a date flag" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  COMP_WORDS=(krisp-get --on 2026-07-10 '')
  COMP_CWORD=3
  COMPREPLY=()
  terminator::krisp::__completion__

  ((${#COMPREPLY[@]} == 0))
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers cached ids for krisp-tag --id" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"
  _seed_cache "${KRISP_MEETING2_JSON}"

  COMP_WORDS=(krisp-tag --id '')
  COMP_CWORD=2
  terminator::krisp::__completion__

  [[ " ${COMPREPLY[*]} " == *' aabbccddeeff00112233445566778899 '* ]]
  [[ " ${COMPREPLY[*]} " == *' 99887766554433221100ffeeddccbbaa '* ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ offers the tag vocabulary for krisp-tag" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'
  _seed_cache "${KRISP_MEETING2_JSON}" 'team'

  # Bare TAG positionals and the --tag, --rename, and --rm slots all offer
  # the library vocabulary.
  COMP_WORDS=(krisp-tag '')
  COMP_CWORD=1
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' work '* ]]
  [[ " ${COMPREPLY[*]} " == *' team '* ]]

  COMP_WORDS=(krisp-tag --tag '')
  COMP_CWORD=2
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' work '* ]]

  COMP_WORDS=(krisp-tag --rename '')
  COMP_CWORD=2
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' team '* ]]

  COMP_WORDS=(krisp-tag --rm '')
  COMP_CWORD=2
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' work '* ]]

  COMP_WORDS=(krisp-tag work '')
  COMP_CWORD=2
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' team '* ]]

  # A typed prefix narrows the vocabulary.
  COMP_WORDS=(krisp-tag te)
  COMP_CWORD=1
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' team '* ]]
  [[ " ${COMPREPLY[*]} " != *' work '* ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::completion
@test "__completion__ clears stale replies for value slots with nothing to offer" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}" 'work'

  COMP_WORDS=(krisp-tag --on '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-tag --since '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-tag --until '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-get -t '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-get --tag '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-cache --tag '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-cache --rm '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))

  COMP_WORDS=(krisp-list --limit '')
  COMP_CWORD=2
  COMPREPLY=('stale')
  terminator::krisp::__completion__
  ((${#COMPREPLY[@]} == 0))
}

################################################################################
# Function existence sweep
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::functions
@test "terminator::krisp defines all public, internal, and lifecycle functions" {
  local fn
  for fn in \
    terminator::krisp::__require_api_key__ \
    terminator::krisp::__require_curl__ \
    terminator::krisp::__require_jq__ \
    terminator::krisp::__tag_valid__ \
    terminator::krisp::__date_valid__ \
    terminator::krisp::__date_next__ \
    terminator::krisp::__api_get__ \
    terminator::krisp::__meetings__ \
    terminator::krisp::__resolve_meeting__ \
    terminator::krisp::__cache_candidates__ \
    terminator::krisp::__cache_entries_in_range__ \
    terminator::krisp::__cache_path__ \
    terminator::krisp::__cache_write__ \
    terminator::krisp::__cache_read__ \
    terminator::krisp::__cache_entry_valid__ \
    terminator::krisp::__cache_entry_tags__ \
    terminator::krisp::__cache_set_tags__ \
    terminator::krisp::__cache_retag__ \
    terminator::krisp::__cache_untag__ \
    terminator::krisp::__cache_rename_tag__ \
    terminator::krisp::__tag_vocabulary__ \
    terminator::krisp::__tag_apply__ \
    terminator::krisp::__tag_rename__ \
    terminator::krisp::__range_fetch__ \
    terminator::krisp::__format_transcript__ \
    terminator::krisp::__cache_filename__ \
    terminator::krisp::__render_markdown__ \
    terminator::krisp::__human_size__ \
    terminator::krisp::__migrate_legacy_cache__ \
    terminator::krisp::__migrate_cache_names__ \
    terminator::krisp::__json_pull__ \
    terminator::krisp::__single_pull__ \
    terminator::krisp::__range_pull__ \
    terminator::krisp::__cache_select__ \
    terminator::krisp::__cache_rm__ \
    terminator::krisp::__cache_clear__ \
    terminator::krisp::__color_auto__ \
    terminator::krisp::__tag_token__ \
    terminator::krisp::__cache_view_rows__ \
    terminator::krisp::__cache_view__ \
    terminator::krisp::__pick_entries__ \
    terminator::krisp::__pick_tags__ \
    terminator::krisp::__usage__ \
    terminator::krisp::list \
    terminator::krisp::get \
    terminator::krisp::cache \
    terminator::krisp::tag \
    terminator::krisp::__completion__ \
    terminator::krisp::__enable__ \
    terminator::krisp::__disable__ \
    terminator::krisp::__export__ \
    terminator::krisp::__recall__; do
    declare -F "${fn}" >/dev/null || {
      echo "missing function: ${fn}"
      return 1
    }
  done
}
