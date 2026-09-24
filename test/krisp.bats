#!/usr/bin/env bats

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

# Seeds a cached transcript: renders BODY into its lexical markdown entry.
# Usage: _seed_cache BODY
_seed_cache() {
  local filename
  terminator::krisp::__cache_filename__ "$1" filename
  mkdir -p "${TERMINATOR_KRISP_CACHE_DIR}"
  terminator::krisp::__render_markdown__ "$1" >"${TERMINATOR_KRISP_CACHE_DIR}/${filename}"
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

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get rejects unknown options" {
  _krisp_env

  run terminator::krisp::get --bogus

  assert_failure
  assert_output --partial 'unknown option'
}

# bats test_tags=terminator::krisp,terminator::krisp::cache
@test "terminator::krisp::cache rejects unknown options" {
  run terminator::krisp::cache --bogus

  assert_failure
  assert_output --partial 'unknown option'
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
# terminator::krisp::list (mocked curl)
################################################################################

# bats test_tags=terminator::krisp,terminator::krisp::list
@test "terminator::krisp::list prints one row per meeting" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::list

  assert_success
  assert_output --partial 'aabbccdd  2026-07-10 09:30Z  Weekly sync'
  assert_output --partial '99887766  2026-07-11 14:00Z  Design review'
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
  assert_output --partial '99887766  2026-07-11 14:00Z  Design review'
  assert_output --partial 'aabbccdd  2026-07-10 09:30Z  Weekly sync'
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
  assert_output --partial '99887766  2026-07-11 14:00Z  Design review'
  assert_output --partial 'aabbccdd  2026-07-10 09:30Z  Weekly sync'
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
  assert_output --partial '99887766  2026-07-11 14:00Z  Design review'
  refute_output --partial 'aabbccdd  2026-07-10 09:30Z  Weekly sync'
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
  assert_output --partial '# Design review'
  assert_output --partial 'id: 99887766554433221100ffeeddccbbaa'
  assert_output --partial 'started_at: 2026-07-11T14:00:00Z'
  assert_output --partial 'duration: 30m 0s'
  assert_output --partial 'Dana Ng [00:00:03]: walking through the mockups'
  # The older Weekly sync meeting must not be served.
  refute_output --partial 'lets get started'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get formats names, fallbacks, and hour rollover" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get aabbccdd

  assert_success
  assert_output --partial '# Weekly sync'
  assert_output --partial 'id: aabbccddeeff00112233445566778899'
  assert_output --partial 'started_at: 2026-07-10T09:30:00Z'
  assert_output --partial 'duration: 1h 0m 0s'
  # Full name from the speakers map.
  assert_output --partial 'Casey Rivera [00:00:05]: lets get started'
  # No name -> email fallback.
  assert_output --partial 'sam@example.com [00:00:11]: sounds good'
  # Absent from the speakers map -> generic label.
  assert_output --partial 'Speaker 3 [00:01:00]: unidentified voice'
  # Past one hour -> hh:mm:ss rolls over.
  assert_output --partial 'Casey Rivera [01:02:05]: wrapping up'
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get resolves a unique prefix via the live list" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get 99887766

  assert_success
  assert_output --partial 'Dana Ng [00:00:03]: walking through the mockups'
  refute_output --partial 'lets get started'
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
  assert_output --partial 'Casey Rivera [00:00:05]: lets get started'
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
  assert_output --partial 'Casey Rivera [00:00:05]: lets get started'
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
  assert_output --partial 'Casey Rivera [00:00:05]: lets get started'
  refute_output --partial 'old cached line'
  # The fresh entry lands under its proper lexical name and the stale
  # same-id entry is removed.
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
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
  assert_output '---
doc_type: transcript
id: aabbccddeeff00112233445566778899
title: "Weekly sync"
started_at: 2026-07-10T09:30:00Z
duration: 1h 0m 0s
language: en
---

# Weekly sync

Casey Rivera [00:00:05]: lets get started'
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
  assert_output '# Weekly sync
2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)

Casey Rivera [00:00:05]: lets get started'
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
  assert_output --partial 'id: aabbccddeeff00112233445566778899'
  assert_output --partial '# Weekly sync'
  assert_output --partial 'Casey Rivera [00:00:05]: lets get started'
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
@test "terminator::krisp::get -q with a cached prefix prints nothing" {
  _krisp_env
  _seed_cache "${KRISP_MEETING_JSON}"

  # Any curl invocation fails the test: the cache must serve fully offline.
  # shellcheck disable=SC2317 # invoked indirectly
  function curl {
    echo "unexpected curl call: $*" >&2
    return 1
  }

  run terminator::krisp::get -q aabbccdd

  assert_success
  assert_output ''
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get -q on a miss fetches and warms silently" {
  _krisp_env
  _krisp_curl_ok

  run terminator::krisp::get -q aabbccdd

  assert_success
  assert_output ''
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get -q keeps failures off stdout" {
  _krisp_env

  # shellcheck disable=SC2317 # invoked indirectly
  function curl { return 7; }

  run --separate-stderr terminator::krisp::get -q aabbccdd

  assert_failure
  assert_output ''
  [[ -n "${stderr}" ]]
}

# bats test_tags=terminator::krisp,terminator::krisp::get
@test "terminator::krisp::get -q --json is contradictory" {
  _krisp_env

  run terminator::krisp::get -q --json aabbccdd

  assert_failure
  assert_output --partial 'contradictory'
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
  assert_line --index 1 --partial '2026-07-10T09-30-00Z  aabbccddeeff00112233445566778899'
  assert_line --index 1 --partial 'Weekly-sync'
  assert_line --index 2 --partial '2026-07-11T14-00-00Z  99887766554433221100ffeeddccbbaa'
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
  assert_output --partial '2026-07-10T09-30-00Z  aabbccddeeff00112233445566778899'

  # The migrated entry serves fully offline.
  unset KRISP_API_KEY
  run terminator::krisp::get aabbccdd

  assert_success
  assert_output --partial '2026-07-10T09:30:00Z (id aabbccddeeff00112233445566778899)'
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
  assert_output --partial 'Casey Rivera [00:00:05]: lets get started'
  refute_output --partial 'old cached line'
  grep -q 'lets get started' "${TERMINATOR_KRISP_CACHE_DIR}/${KRISP_MEETING_MD}"
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
  [[ " ${COMPREPLY[*]} " == *' --quiet '* ]]

  COMP_WORDS=(krisp-cache -)
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' --rm '* ]]

  COMP_WORDS=(krisp-list -)
  COMP_CWORD=1
  COMPREPLY=()
  terminator::krisp::__completion__
  [[ " ${COMPREPLY[*]} " == *' --limit '* ]]
  [[ " ${COMPREPLY[*]} " == *' --since '* ]]
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
    terminator::krisp::__api_get__ \
    terminator::krisp::__meetings__ \
    terminator::krisp::__resolve_meeting__ \
    terminator::krisp::__cache_candidates__ \
    terminator::krisp::__cache_path__ \
    terminator::krisp::__cache_write__ \
    terminator::krisp::__cache_read__ \
    terminator::krisp::__cache_entry_valid__ \
    terminator::krisp::__format_transcript__ \
    terminator::krisp::__cache_filename__ \
    terminator::krisp::__render_markdown__ \
    terminator::krisp::__human_size__ \
    terminator::krisp::__migrate_legacy_cache__ \
    terminator::krisp::__migrate_cache_names__ \
    terminator::krisp::__usage__ \
    terminator::krisp::list \
    terminator::krisp::get \
    terminator::krisp::cache \
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
