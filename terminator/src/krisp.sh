#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

terminator::__module__::load || return 0

################################################################################
# Global state
################################################################################

# Krisp Meeting API base URL (overridable so tests can point elsewhere).
TERMINATOR_KRISP_API_URL="${TERMINATOR_KRISP_API_URL:-https://meeting-api.krisp.ai/v1}"

# Directory where fetched transcripts are cached as lexical markdown files
# (overridable via env; not under ~/.terminator, which homesick symlinks
# into this repo).
TERMINATOR_KRISP_CACHE_DIR="${TERMINATOR_KRISP_CACHE_DIR:-${HOME}/.cache/terminator/krisp}"

# KRISP_API_KEY comes from the environment (e.g. a hooks/after script outside
# this repo) and is checked lazily at call time.

################################################################################
# Enable / disable
################################################################################

function terminator::krisp::__enable__ {
  alias krisp-list='terminator::krisp::list'
  alias krisp-get='terminator::krisp::get'
  alias krisp-cache='terminator::krisp::cache'

  complete -F terminator::krisp::__completion__ krisp-list
  complete -F terminator::krisp::__completion__ krisp-get
  complete -F terminator::krisp::__completion__ krisp-cache
}

function terminator::krisp::__disable__ {
  unalias krisp-list 2>/dev/null
  unalias krisp-get 2>/dev/null
  unalias krisp-cache 2>/dev/null

  complete -r krisp-list 2>/dev/null
  complete -r krisp-get 2>/dev/null
  complete -r krisp-cache 2>/dev/null
}

################################################################################
# Internal functions
################################################################################

# Ensures KRISP_API_KEY is set. Lazy: called at command time, never at enable
# time, so a missing key does not spam every new shell.
function terminator::krisp::__require_api_key__ {
  if [[ -z "${KRISP_API_KEY}" ]]; then
    terminator::logger::error 'KRISP_API_KEY is not set (export it, e.g. via a hooks/after script)'
    return 1
  fi
}

# Ensures curl is installed.
function terminator::krisp::__require_curl__ {
  if ! terminator::command::exists curl; then
    terminator::logger::error 'curl is required but not installed'
    return 1
  fi
}

# Ensures jq is installed.
function terminator::krisp::__require_jq__ {
  if ! terminator::command::exists jq; then
    terminator::logger::error 'jq is required but not installed'
    return 1
  fi
}

# Performs a GET request against the Krisp Meeting API.
# Captures the response body and HTTP status code via printf -v. The
# Authorization header is built here and never logged or echoed.
# Usage: __api_get__ BODY_VAR CODE_VAR PATH [QUERY]
function terminator::krisp::__api_get__ {
  local \
    path="$3" \
    query="$4" \
    url \
    rc \
    __api_get_response__

  url="${TERMINATOR_KRISP_API_URL%/}${path}"
  [[ -n "${query}" ]] && url="${url}?${query}"

  # curl appends '\n%{http_code}' after the body, so the last line is the code.
  __api_get_response__="$(curl -sS \
    -H "Authorization: Bearer ${KRISP_API_KEY}" \
    -w '\n%{http_code}' \
    "${url}")"
  rc=$?

  if ((rc != 0)); then
    terminator::logger::error "krisp request failed (curl exit ${rc})"
    return 1
  fi

  printf -v "$2" '%s' "${__api_get_response__##*$'\n'}"
  printf -v "$1" '%s' "${__api_get_response__%$'\n'*}"
}

# Fetches up to LIMIT meetings as a single JSON array of meeting objects,
# newest first, optionally bounded by FROM/TO dates (passed through to the
# API's native from/to params). Paginates via next_cursor when LIMIT
# exceeds the API's 100-per-request cap; LIMIT=0 means unbounded (page
# until the API is exhausted). Returns 1 on request or HTTP failure.
# Usage: __meetings__ OUTPUT_VAR [LIMIT] [FROM] [TO]
function terminator::krisp::__meetings__ {
  local \
    __meetings_out__="$1" \
    limit="${2:-10}" \
    from="${3:-}" \
    to="${4:-}" \
    remaining \
    page_size \
    cursor="" \
    query \
    body \
    code \
    count \
    lines=""

  remaining="${limit}"

  while ((limit == 0 || remaining > 0)); do
    if ((limit == 0 || remaining > 100)); then
      page_size=100
    else
      page_size="${remaining}"
    fi

    query="sort_by=date&order=newest&limit=${page_size}"
    [[ -n "${from}" ]] && query="${query}&from=${from}"
    [[ -n "${to}" ]] && query="${query}&to=${to}"
    [[ -n "${cursor}" ]] && query="${query}&cursor=${cursor}"

    terminator::krisp::__api_get__ body code '/meetings' "${query}" || return 1

    if ((code != 200)); then
      terminator::logger::error "krisp: list meetings failed (HTTP ${code})"
      return 1
    fi

    lines+="${lines:+$'\n'}$(jq -c '.meetings[]?' <<<"${body}" 2>/dev/null)"
    count="$(jq '.meetings | length' <<<"${body}" 2>/dev/null)"
    [[ "${count}" =~ ^[0-9]+$ ]] || count=0
    remaining=$((remaining - count))
    cursor="$(jq -r '.next_cursor // empty' <<<"${body}" 2>/dev/null)"

    # Nothing more to page through: no cursor, or an empty page.
    if [[ -z "${cursor}" ]] || ((count == 0)); then
      break
    fi
  done

  printf -v "${__meetings_out__}" '%s' "$(jq -s '.' <<<"${lines}")"
}

# Echoes candidate meeting ids whose lexical cache entry matches PREFIX, one
# per line, offline. Entries are <timestamp>Z__<id>__<slug>.md files and
# the id is the second double-underscore-separated segment, matched
# literally against PREFIX (quoted in [[ ]], so metacharacters stay
# literal). A PREFIX containing "/" never matches, so the glob cannot
# escape the cache dir.
# Usage: __cache_candidates__ PREFIX
function terminator::krisp::__cache_candidates__ {
  local \
    token="$1" \
    entry \
    id

  [[ "${token}" != */* ]] || return 0

  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*_*.md; do
    [[ -f "${entry}" ]] || continue
    entry="${entry##*/}"
    # Lexical grammar: <timestamp>Z__<id>__<slug>.md; the id is segment 2.
    [[ "${entry}" == *__*__*.md ]] || continue
    id="${entry#*__}"
    id="${id%%__*}"
    [[ -n "${id}" ]] || continue
    [[ "${id}" == "${token}"* ]] || continue
    printf '%s\n' "${id}"
  done
}

# Resolves a meeting id PREFIX to the full id. Cache entries are searched
# first, so an already-fetched meeting resolves offline; an uncached prefix
# falls back to a live list. Returns 0 on a unique match, 1 when nothing
# matches, 2 when the prefix is ambiguous (candidates are logged either way).
# Usage: __resolve_meeting__ OUTPUT_VAR PREFIX
function terminator::krisp::__resolve_meeting__ {
  local \
    __resolve_meeting_out__="$1" \
    token="$2" \
    entry \
    meetings \
    candidates=()

  # Cache first: lexical markdown filenames, offline.
  while IFS= read -r entry; do
    candidates+=("${entry}")
  done < <(terminator::krisp::__cache_candidates__ "${token}")

  # Not cached: fall back to a live list of the 100 newest meetings.
  if ((${#candidates[@]} == 0)); then
    terminator::krisp::__meetings__ meetings 100 || return 1
    while IFS= read -r entry; do
      [[ "${entry}" == "${token}"* ]] && candidates+=("${entry}")
    done < <(jq -r '.[].id' <<<"${meetings}")
  fi

  case "${#candidates[@]}" in
    0)
      terminator::logger::error "no meeting matches '${token}'"
      return 1
      ;;
    1)
      printf -v "${__resolve_meeting_out__}" '%s' "${candidates[0]}"
      ;;
    *)
      terminator::logger::error "ambiguous meeting prefix '${token}': ${candidates[*]}"
      return 2
      ;;
  esac
}

# Resolves the existing lexical cache entry for a full meeting id, or fails
# when no entry exists. The id is quoted inside the glob, so
# metacharacters in it stay literal and match no file. The single-underscore
# glob deliberately matches both the current <ts>Z__<id>__<slug>.md grammar
# and pre-migration <ts>_<id>_<slug>.md names.
# Usage: __cache_path__ ID [OUTPUT_VAR]
function terminator::krisp::__cache_path__ {
  local \
    __cache_path_result__ \
    entry

  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*_"$1"_*.md; do
    [[ -f "${entry}" ]] || continue
    entry="${entry##*/}"
    [[ "${entry}" == *_"$1"_*.md ]] || continue
    __cache_path_result__="${TERMINATOR_KRISP_CACHE_DIR}/${entry}"
    break
  done

  [[ -n "${__cache_path_result__}" ]] || return 1

  case "$#" in
    2) printf -v "$2" '%s' "${__cache_path_result__}" ;;
    *) echo "${__cache_path_result__}" ;;
  esac
}

# Writes the rendered markdown entry to the cache atomically (tmp + mv),
# then removes any other entry for the same id: a stale lexical name (e.g.
# a corrected started_at or a pre-migration single-underscore name) or a
# legacy {id}.json. The single-underscore globs deliberately match both
# grammars.
# Usage: __cache_write__ ID BODY
function terminator::krisp::__cache_write__ {
  local \
    id="$1" \
    body="$2" \
    filename \
    path \
    tmp \
    entry

  terminator::krisp::__cache_filename__ "${body}" filename
  if [[ -z "${filename}" ]]; then
    terminator::logger::error "failed to derive cache filename for meeting '${id}'"
    return 1
  fi
  path="${TERMINATOR_KRISP_CACHE_DIR}/${filename}"
  # $$ and $RANDOM keep concurrent writers from sharing a tmp path, whether
  # separate processes or background jobs from one shell.
  tmp="${path}.tmp.$$.$RANDOM"

  mkdir -p "${TERMINATOR_KRISP_CACHE_DIR}"
  if terminator::krisp::__render_markdown__ "${body}" >"${tmp}" && mv "${tmp}" "${path}"; then
    for entry in \
      "${TERMINATOR_KRISP_CACHE_DIR}"/*_"${id}"_*.md \
      "${TERMINATOR_KRISP_CACHE_DIR}/${id}.json" \
      "${TERMINATOR_KRISP_CACHE_DIR}/${id}.json.tmp."*; do
      [[ -f "${entry}" ]] || continue
      [[ "${entry##*/}" != "${filename}" ]] || continue
      rm -f "${entry}"
    done
    return 0
  fi
  rm -f "${tmp}"
  terminator::logger::error "failed to write cache entry for meeting '${id}'"
  return 1
}

# Reads a cached response, degrading to empty output when it is absent or
# unreadable. Usage: __cache_read__ FILE [OUTPUT_VAR]
function terminator::krisp::__cache_read__ {
  local __cache_read_result__

  if [[ -r "$1" ]]; then
    __cache_read_result__="$(cat "$1")"
  else
    __cache_read_result__=""
  fi

  case "$#" in
    2) printf -v "$2" '%s' "${__cache_read_result__}" ;;
    *) echo "${__cache_read_result__}" ;;
  esac
}

# Validates a cache entry body against a meeting id. Both the current
# frontmatter format and the older two-line header pass, so pre-existing
# entries keep serving.
# Usage: __cache_entry_valid__ ID BODY
function terminator::krisp::__cache_entry_valid__ {
  local \
    id="$1" \
    body="$2" \
    line1 \
    line2 \
    front

  line1="${body%%$'\n'*}"
  if [[ "${line1}" == '---' ]]; then
    # Everything up to the closing delimiter.
    front="${body%%$'\n---'*}"
    case "${front}" in
      *$'\n'"id: ${id}"$'\n'* | *$'\n'"id: ${id}") return 0 ;;
      *) return 1 ;;
    esac
  fi

  line2="${body#*$'\n'}"
  line2="${line2%%$'\n'*}"
  [[ "${line1}" == '# '* ]] && [[ "${line2}" == *"(id ${id})"* ]]
}

# Formats a meeting API response as one line per segment:
#   Name [hh:mm:ss]: text
# Speaker names come from the transcript.speakers map (keyed by diarization
# index), falling back to the participant email, then "Speaker N". Field
# accesses are defensive so an unexpected shape prints nothing.
# Usage: __format_transcript__ BODY
function terminator::krisp::__format_transcript__ {
  jq -r '
    def pad: tostring | if length < 2 then "0" + . else . end;
    def ts: "\(./3600 | floor | pad):\(./60 % 60 | floor | pad):\(. % 60 | floor | pad)";
    def speaker_name($idx):
      (.speakers[$idx] // {}) as $p
      | ([$p.first_name // "", $p.last_name // ""] | join(" ") | gsub("^ +| +$"; ""))
      | if . == "" then ($p.email // "") else . end
      | if . == "" then "Speaker \($idx)" else . end;
    (.transcript // {}) as $t
    | $t.segments[]?
    | . as $seg
    | (.speaker | tostring) as $idx
    | "\($t | speaker_name($idx)) [\($seg.start // 0 | ts)]: \($seg.text // "")"
  ' <<<"$1" 2>/dev/null
}

# Builds the lexical cache filename for a meeting response:
#   YYYY-MM-DDTHH-MM-SSZ__<full-id>__<slug>.md
# The timestamp is started_at truncated to second precision (real values
# carry milliseconds) with colons as hyphens and a literal Z appended
# (started_at is UTC); a missing, empty, or short started_at becomes the
# epoch. The slug collapses every non-ASCII-alphanumeric title run to one
# hyphen (the Krisp desktop app style), trims hyphens, truncates to 80
# chars, and defaults to "untitled"; it never contains underscores, so the
# name is exactly three double-underscore-separated segments plus .md.
# Usage: __cache_filename__ BODY [OUTPUT_VAR]
function terminator::krisp::__cache_filename__ {
  local __cache_filename_result__

  __cache_filename_result__="$(jq -r '
    (if ((.started_at // "") | length) >= 19
      then (.started_at | .[0:19])
      else "1970-01-01T00:00:00" end) as $iso
    | (.title // ""
      | gsub("[^A-Za-z0-9]+"; "-")
      | gsub("^-+|-+$"; "")
      | if length > 80 then .[0:80] | gsub("-+$"; "") else . end
      | if length == 0 then "untitled" else . end) as $slug
    | "\($iso | gsub(":"; "-"))Z__\(.id // "")__\($slug).md"
  ' <<<"$1" 2>/dev/null)"

  case "$#" in
    2) printf -v "$2" '%s' "${__cache_filename_result__}" ;;
    *) echo "${__cache_filename_result__}" ;;
  esac
}

# Renders a meeting response as the markdown cache entry: a frontmatter
# block, the title, a blank line, then the formatted transcript. The cache
# entry and krisp-get stdout are byte-identical.
# Usage: __render_markdown__ BODY [OUTPUT_VAR]
function terminator::krisp::__render_markdown__ {
  local \
    __render_markdown_result__ \
    __render_markdown_header__

  __render_markdown_header__="$(jq -r '
    def hms($d):
      (if $d >= 3600 then "\($d / 3600 | floor)h " else "" end)
      + "\($d / 60 % 60 | floor)m \($d % 60 | floor)s";
    (if ((.started_at // "") | length) >= 19
      then (.started_at | .[0:19])
      else "1970-01-01T00:00:00" end) as $iso
    | ((.duration | numbers) // 0) as $d
    | ((.transcript // {} | .language? // "" | strings // "")) as $lang
    | "---",
      "doc_type: transcript",
      "id: \(.id // "")",
      "title: \(.title // "(untitled)" | tojson)",
      "started_at: \($iso)Z",
      (if $d > 0 then "duration: \(hms($d))" else empty end),
      (if $lang != "" then "language: \($lang)" else empty end),
      "---",
      "",
      "# \(.title // "(untitled)")"
  ' <<<"$1" 2>/dev/null)"

  __render_markdown_result__="${__render_markdown_header__}

$(terminator::krisp::__format_transcript__ "$1")"

  case "$#" in
    2) printf -v "$2" '%s' "${__render_markdown_result__}" ;;
    *) printf '%s\n' "${__render_markdown_result__}" ;;
  esac
}

# Formats a byte count for humans: bytes below 1024 print as NB, otherwise
# one decimal place plus K, M, or G.
# Usage: __human_size__ BYTES [OUTPUT_VAR]
function terminator::krisp::__human_size__ {
  local \
    bytes="$1" \
    __human_size_result__

  if ((bytes < 1024)); then
    __human_size_result__="${bytes}B"
  elif ((bytes < 1048576)); then
    __human_size_result__="$((bytes / 1024)).$(((bytes % 1024) * 10 / 1024))K"
  elif ((bytes < 1073741824)); then
    __human_size_result__="$((bytes / 1048576)).$(((bytes % 1048576) * 10 / 1048576))M"
  else
    __human_size_result__="$((bytes / 1073741824)).$(((bytes % 1073741824) * 10 / 1073741824))G"
  fi

  case "$#" in
    2) printf -v "$2" '%s' "${__human_size_result__}" ;;
    *) echo "${__human_size_result__}" ;;
  esac
}

# Migrates legacy {id}.json cache entries to lexical markdown entries:
# renders each body into its lexical entry, then removes the legacy file.
# A legacy id that already has a lexical entry is dropped without
# rendering; a failed render leaves the legacy file in place. Writes the
# number of migrated entries to OUTPUT_VAR.
# Usage: __migrate_legacy_cache__ OUTPUT_VAR
function terminator::krisp::__migrate_legacy_cache__ {
  local \
    __migrate_out__="$1" \
    entry \
    id \
    body \
    __migrate_count__=0

  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*.json; do
    [[ -f "${entry}" ]] || continue
    id="${entry##*/}"
    id="${id%.json}"

    # A lexical entry for the same id supersedes the legacy file.
    if [[ -n "$(terminator::krisp::__cache_candidates__ "${id}")" ]]; then
      rm -f "${entry}"
      continue
    fi

    terminator::krisp::__cache_read__ "${entry}" body
    if terminator::krisp::__cache_write__ "${id}" "${body}"; then
      rm -f "${entry}"
      __migrate_count__=$((__migrate_count__ + 1))
    else
      # Never lose the only copy; leave it for a later retry.
      terminator::logger::error "failed to migrate legacy cache entry '${id}'; leaving it in place"
    fi
  done

  printf -v "${__migrate_out__}" '%s' "${__migrate_count__}"
}

# Renames old-grammar lexical entries (<timestamp>_<id>_<slug>.md, no Z)
# to the current grammar (<timestamp>Z__<id>__<slug>.md). The new name is
# derived purely from the old one, so no key, curl, or jq is needed. A
# current-grammar entry for the same id supersedes the old name (removed);
# a name matching neither grammar is left alone. After a rename, header
# line 2 is rebuilt as full ISO from the filename, best-effort: a failed
# rewrite keeps the renamed file (the old header still serves). Writes
# the number of renamed entries to OUTPUT_VAR.
# Usage: __migrate_cache_names__ OUTPUT_VAR
function terminator::krisp::__migrate_cache_names__ {
  local \
    __migrate_names_out__="$1" \
    entry \
    filename \
    target \
    ts \
    id \
    content \
    rest \
    line2 \
    tmp \
    __migrate_names_count__=0

  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*.md; do
    [[ -f "${entry}" ]] || continue
    filename="${entry##*/}"

    # Current grammar already; nothing to migrate.
    [[ "${filename}" == *__*__*.md ]] && continue

    # Strict old grammar: <timestamp>_<id>_<slug>.md.
    [[ "${filename}" =~ ^([^_]+)_([^_]+)_([^_]+)\.md$ ]] || continue
    ts="${BASH_REMATCH[1]}"
    id="${BASH_REMATCH[2]}"
    target="${TERMINATOR_KRISP_CACHE_DIR}/${ts}Z__${id}__${BASH_REMATCH[3]}.md"

    # A current-grammar entry for the same id supersedes the old name.
    if [[ -f "${target}" ]]; then
      rm -f "${entry}"
      continue
    fi

    if ! mv "${entry}" "${target}"; then
      # Never lose the only copy; leave it for a later retry.
      terminator::logger::error "failed to migrate cache filename '${filename}'; leaving it in place"
      continue
    fi
    __migrate_names_count__=$((__migrate_names_count__ + 1))

    # Best-effort: rebuild header line 2 as full ISO from the filename.
    terminator::krisp::__cache_read__ "${target}" content
    rest="${content#*$'\n'}"
    if [[ "${rest}" == *$'\n'* ]]; then
      rest="${rest#*$'\n'}"
      line2="${ts:0:10}T${ts:11:2}:${ts:14:2}:${ts:17:2}Z (id ${id})"
      tmp="${target}.tmp.$$.$RANDOM"
      if printf '%s\n%s\n%s\n' \
        "${content%%$'\n'*}" "${line2}" "${rest}" >"${tmp}" \
        && mv "${tmp}" "${target}"; then
        :
      else
        rm -f "${tmp}"
        terminator::logger::warning "failed to rewrite header of '${target##*/}'; keeping the old header"
      fi
    fi
  done

  printf -v "${__migrate_names_out__}" '%s' "${__migrate_names_count__}"
}

# Prints usage for a krisp command. Usage: __usage__ COMMAND
function terminator::krisp::__usage__ {
  case "$1" in
    krisp-list)
      cat <<USAGE_TEXT
Usage: krisp-list [OPTIONS]

  List recent Krisp meetings, newest first.

  Options:
    -l, --limit N             Number of meetings to show (default: 10)
    --since DATE              Only meetings from DATE on (YYYY-MM-DD or ISO)
    --until DATE              Only meetings before DATE (YYYY-MM-DD or ISO)
    -h, --help                Show this help

  A date range without --limit lists every meeting in the range.
USAGE_TEXT
      ;;
    krisp-get)
      cat <<USAGE_TEXT
Usage: krisp-get [OPTIONS] [PREFIX]

  Print the transcript of a Krisp meeting as markdown. With no PREFIX,
  targets the most recent meeting. A cached meeting serves fully offline.

  Arguments:
    PREFIX                    Meeting id prefix (from krisp-list or cache)

  Options:
    -q, --quiet               Pull without printing anything; the exit
                              status carries the result
    --json                    Print the raw API response instead; always
                              fetches live and never touches the cache
    --refresh                 Skip the cache and fetch fresh from the API
    -h, --help                Show this help

  Cache entries are markdown files named YYYY-MM-DDTHH-MM-SSZ__id__slug.md,
  so the cache dir doubles as a browsable transcript library. Each entry
  opens with a YAML frontmatter block (doc_type, id, title, started_at,
  duration, language), then the title heading, then one line per spoken
  segment.

  Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}
USAGE_TEXT
      ;;
    krisp-cache)
      cat <<USAGE_TEXT
Usage: krisp-cache [OPTIONS]

  Show the transcript library: the cache dir and one line per cached
  transcript, oldest first. Old filename grammars and legacy .json entries
  are migrated on view.

  Options:
    --rm PREFIX               Remove one cached transcript (meeting id
                              prefix)
    --clear                   Remove every cached transcript
    -h, --help                Show this help

  Cached transcripts are regenerable from the API, so neither option asks
  for confirmation, but both delete the only local copy: a later fetch
  re-creates the entry.

  Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}
USAGE_TEXT
      ;;
  esac
}

################################################################################
# Public functions
################################################################################

# Lists recent Krisp meetings, newest first, one per line:
#   short-id  date time  title  [status]
# The status marker only appears for meetings that are not ready yet.
function terminator::krisp::list {
  local \
    limit=10 \
    limit_set=0 \
    since="" \
    until="" \
    date \
    meetings \
    count

  while (($# != 0)); do
    case "$1" in
      -l | --limit)
        shift
        limit="$1"
        limit_set=1
        ;;
      --since)
        shift
        since="$1"
        ;;
      --until)
        shift
        until="$1"
        ;;
      -h | --help)
        terminator::krisp::__usage__ krisp-list
        return 0
        ;;
      *)
        terminator::logger::error "krisp-list unknown option: '$1'"
        return 1
        ;;
    esac
    shift
  done

  if ! [[ "${limit}" =~ ^[1-9][0-9]*$ ]]; then
    terminator::logger::error "krisp-list invalid limit: '${limit}'"
    return 1
  fi

  for date in "${since}" "${until}"; do
    [[ -z "${date}" ]] && continue
    if ! [[ "${date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
      terminator::logger::error "krisp-list invalid date: '${date}' (expected YYYY-MM-DD or ISO timestamp)"
      return 1
    fi
  done

  # A date bound without an explicit --limit means "everything in range":
  # page until the API is exhausted.
  if ((limit_set == 0)) && [[ -n "${since}" || -n "${until}" ]]; then
    limit=0
  fi

  terminator::krisp::__require_api_key__ || return 1
  terminator::krisp::__require_curl__ || return 1
  terminator::krisp::__require_jq__ || return 1

  terminator::krisp::__meetings__ meetings "${limit}" "${since}" "${until}" || return 1

  count="$(jq 'length' <<<"${meetings}")"
  if ((count == 0)); then
    echo '(no meetings)'
    return 0
  fi

  jq -r '
    .[] |
    (.id // "?" | .[0:8]) as $id |
    (.started_at // "") as $st |
    (if $st == "" then "-" else ($st[0:10] + " " + $st[11:16] + "Z") end) as $when |
    (if (.status // "ready") != "ready" then "  [\(.status)]" else "" end) as $status |
    "\($id)  \($when)  \(.title // "(untitled)")\($status)"
  ' <<<"${meetings}"
}

# Prints the transcript of a Krisp meeting as markdown. With no PREFIX,
# targets the most recent meeting. PREFIX may be any unique prefix of a
# meeting id; a cached meeting resolves and serves fully offline (no key,
# curl, or jq). -q suppresses stdout entirely: the exit status carries the
# result. --json always fetches live and prints the raw response, never
# touching the cache. A 409 (transcription still processing) prints a
# friendly message, exits 1, and never writes the cache.
function terminator::krisp::get {
  local \
    token="" \
    json=0 \
    refresh=0 \
    quiet=0 \
    from_cache=0 \
    meetings \
    id="" \
    path \
    body \
    code \
    entry \
    candidates=()

  while (($# != 0)); do
    case "$1" in
      -q | --quiet)
        quiet=1
        ;;
      --json)
        json=1
        ;;
      --refresh)
        refresh=1
        ;;
      -h | --help)
        terminator::krisp::__usage__ krisp-get
        return 0
        ;;
      -*)
        terminator::logger::error "krisp-get unknown option: '$1'"
        return 1
        ;;
      *)
        if [[ -n "${token}" ]]; then
          terminator::logger::error "krisp-get unexpected argument: '$1'"
          return 1
        fi
        token="$1"
        ;;
    esac
    shift
  done

  if ((quiet == 1 && json == 1)); then
    terminator::logger::error 'krisp-get --quiet and --json are contradictory'
    return 1
  fi

  # Offline fast path: a unique cached prefix serves before any guard or
  # fetch, so cached meetings work with KRISP_API_KEY unset.
  if [[ -n "${token}" ]] && ((refresh == 0)); then
    while IFS= read -r entry; do
      candidates+=("${entry}")
    done < <(terminator::krisp::__cache_candidates__ "${token}")
    if ((${#candidates[@]} == 1)); then
      id="${candidates[0]}"
      from_cache=1
    elif ((${#candidates[@]} > 1)); then
      # Ambiguity is determinable offline; never mask it behind the guards.
      terminator::logger::error "ambiguous meeting prefix '${token}': ${candidates[*]}"
      return 1
    fi
  fi

  if [[ -z "${id}" ]]; then
    terminator::krisp::__require_api_key__ || return 1
    terminator::krisp::__require_curl__ || return 1
    terminator::krisp::__require_jq__ || return 1

    if [[ -n "${token}" ]]; then
      # Both "not found" (1) and "ambiguous" (2) already logged their error.
      terminator::krisp::__resolve_meeting__ id "${token}" || return 1
    else
      # No prefix: target the most recent meeting.
      terminator::krisp::__meetings__ meetings 1 || return 1
      id="$(jq -r '.[0].id // empty' <<<"${meetings}")"
      if [[ -z "${id}" ]]; then
        terminator::logger::error 'no meetings found'
        return 1
      fi
    fi
  fi

  # Cache hit: the entry is pre-rendered markdown, so serving needs no key,
  # curl, or jq. A readable entry that fails validation is corrupt and is
  # never silently re-fetched.
  if ((json == 0)) && ((refresh == 0)) && terminator::krisp::__cache_path__ "${id}" path; then
    terminator::krisp::__cache_read__ "${path}" body

    if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
      terminator::logger::error "cache entry for '${id}' is corrupt; re-fetch with --refresh"
      return 1
    fi

    if ((quiet == 1)); then
      return 0
    fi
    printf '%s\n' "${body}"
    return 0
  fi

  # A fast-path id never bypasses the guards: --json always fetches live.
  if ((from_cache == 1)); then
    terminator::krisp::__require_api_key__ || return 1
    terminator::krisp::__require_curl__ || return 1
    terminator::krisp::__require_jq__ || return 1
  fi

  terminator::krisp::__api_get__ body code "/meetings/${id}" \
    'fields=title,started_at,duration,status,transcript' || return 1

  if ((code == 409)); then
    terminator::logger::error "transcription for meeting '${id}' is still processing; try again shortly"
    return 1
  fi

  if ((code != 200)); then
    terminator::logger::error "krisp: fetch transcript failed (HTTP ${code}): $(jq -r '.error // empty' <<<"${body}" 2>/dev/null)"
    return 1
  fi

  if ((json == 1)); then
    printf '%s\n' "${body}"
    return 0
  fi

  # An empty transcript is never cached; only --refresh could recover it.
  if ! jq -e '(.transcript.segments // []) | length > 0' <<<"${body}" >/dev/null 2>&1; then
    terminator::logger::error "no transcript in response for meeting '${id}'"
    return 1
  fi

  terminator::krisp::__cache_write__ "${id}" "${body}" || return 1

  if ((quiet == 1)); then
    return 0
  fi

  if ! terminator::krisp::__cache_path__ "${id}" path; then
    terminator::logger::error "cache entry for meeting '${id}' vanished after write"
    return 1
  fi
  terminator::krisp::__cache_read__ "${path}" body
  printf '%s\n' "${body}"
}

# Shows the transcript library: legacy {id}.json entries are migrated to
# lexical markdown entries, then one line per entry is listed, oldest
# first. --rm PREFIX removes a single entry; --clear removes them all.
# Cached transcripts are regenerable from the API, so neither asks for
# confirmation, but both delete the only local copy: a later fetch
# re-creates the entry.
function terminator::krisp::cache {
  local \
    clear=0 \
    rm_token="" \
    entry \
    filename \
    id \
    slug \
    size \
    count=0 \
    total=0 \
    migrated=0 \
    candidates=()

  while (($# != 0)); do
    case "$1" in
      --clear)
        clear=1
        ;;
      --rm)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-cache --rm requires a meeting id prefix'
          return 1
        fi
        rm_token="$1"
        ;;
      -h | --help)
        terminator::krisp::__usage__ krisp-cache
        return 0
        ;;
      *)
        terminator::logger::error "krisp-cache unknown option: '$1'"
        return 1
        ;;
    esac
    shift
  done

  if ((clear == 1)) && [[ -n "${rm_token}" ]]; then
    terminator::logger::error 'krisp-cache --clear and --rm are mutually exclusive'
    return 1
  fi

  # Old-grammar filenames are migrated before --rm resolution so a prefix
  # still matches; --clear skips it.
  if ((clear == 0)); then
    terminator::krisp::__migrate_cache_names__ migrated
    if ((migrated > 0)); then
      echo "Migrated ${migrated} cache filename(s) to the current grammar"
    fi
  fi

  if [[ -n "${rm_token}" ]]; then
    while IFS= read -r entry; do
      candidates+=("${entry}")
    done < <(terminator::krisp::__cache_candidates__ "${rm_token}")

    if ((${#candidates[@]} == 0)); then
      terminator::logger::error "no cached transcript matches '${rm_token}'"
      return 1
    elif ((${#candidates[@]} > 1)); then
      terminator::logger::error "ambiguous meeting prefix '${rm_token}': ${candidates[*]}"
      return 1
    fi

    # Single-underscore glob: deliberately matches both grammars.
    for entry in \
      "${TERMINATOR_KRISP_CACHE_DIR}"/*_"${candidates[0]}"_*.md \
      "${TERMINATOR_KRISP_CACHE_DIR}/${candidates[0]}.json"; do
      [[ -f "${entry}" ]] || continue
      rm -f "${entry}"
      echo "Removed ${entry##*/}"
    done
    return 0
  fi

  if ((clear == 1)); then
    for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*.md; do
      [[ -f "${entry}" ]] && count=$((count + 1))
    done

    # Stale partial writes from interrupted cache writes, both formats.
    rm -f \
      "${TERMINATOR_KRISP_CACHE_DIR}"/*.md \
      "${TERMINATOR_KRISP_CACHE_DIR}"/*.md.tmp.* \
      "${TERMINATOR_KRISP_CACHE_DIR}"/*.json \
      "${TERMINATOR_KRISP_CACHE_DIR}"/*.json.tmp.*
    echo "Cleared ${count} cached transcript(s)"
    return 0
  fi

  if ! terminator::command::exists jq; then
    terminator::logger::warning 'skipping legacy cache migration: jq is required'
  else
    terminator::krisp::__migrate_legacy_cache__ migrated
    if ((migrated > 0)); then
      if ((migrated == 1)); then
        echo 'Migrated 1 legacy cache entry'
      else
        echo "Migrated ${migrated} legacy cache entries"
      fi
    fi
  fi

  echo "Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}"

  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*_*.md; do
    [[ -f "${entry}" ]] || continue
    filename="${entry##*/}"
    # Lexical grammar: <timestamp>Z__<id>__<slug>.md.
    [[ "${filename}" == *__*__*.md ]] || continue
    id="${filename#*__}"
    id="${id%%__*}"
    [[ -n "${id}" ]] || continue
    size="$(wc -c <"${entry}")"
    total=$((total + size))
    count=$((count + 1))
    slug="${filename#*__*__}"
    slug="${slug%.md}"
    echo "${filename%%__*}  ${id}  $(terminator::krisp::__human_size__ "${size}")  ${slug}"
  done

  if ((count == 1)); then
    echo "1 transcript, $(terminator::krisp::__human_size__ "${total}") total"
  else
    echo "${count} transcripts, $(terminator::krisp::__human_size__ "${total}") total"
  fi
}

################################################################################
# Completion
################################################################################

# Tab completion for krisp-list/transcript/cache: cached meeting ids for
# krisp-get only (never an API call), and each command's flags on a
# dash.
function terminator::krisp::__completion__ {
  local \
    cur \
    id \
    ids="" \
    completion \
    entry \
    flags

  if ((COMP_CWORD > 1)); then
    COMPREPLY=()
    return
  fi

  cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "${cur}" == -* ]]; then
    case "${COMP_WORDS[0]}" in
      krisp-list) flags='-l --limit --since --until -h --help' ;;
      krisp-get) flags='-q --quiet --json --refresh -h --help' ;;
      krisp-cache) flags='--rm --clear -h --help' ;;
      *) flags='-h --help' ;;
    esac

    COMPREPLY=()
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "${flags}" -- "${cur}")
    return
  fi

  COMPREPLY=()

  # Only krisp-get takes a meeting id (from the cache, offline).
  if [[ "${COMP_WORDS[0]}" == 'krisp-get' ]]; then
    for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*_*.md; do
      [[ -f "${entry}" ]] || continue
      entry="${entry##*/}"
      # Lexical grammar: <timestamp>Z__<id>__<slug>.md; the id is segment 2.
      [[ "${entry}" == *__*__*.md ]] || continue
      id="${entry#*__}"
      id="${id%%__*}"
      [[ -n "${id}" ]] || continue
      ids+="${ids:+ }${id}"
    done

    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "${ids}" -- "${cur}")
  fi
}

################################################################################
# Export / recall
################################################################################

function terminator::krisp::__export__ {
  export TERMINATOR_KRISP_API_URL
  export TERMINATOR_KRISP_CACHE_DIR

  export -f terminator::krisp::__require_api_key__
  export -f terminator::krisp::__require_curl__
  export -f terminator::krisp::__require_jq__
  export -f terminator::krisp::__api_get__
  export -f terminator::krisp::__meetings__
  export -f terminator::krisp::__resolve_meeting__
  export -f terminator::krisp::__cache_candidates__
  export -f terminator::krisp::__cache_path__
  export -f terminator::krisp::__cache_write__
  export -f terminator::krisp::__cache_read__
  export -f terminator::krisp::__cache_entry_valid__
  export -f terminator::krisp::__format_transcript__
  export -f terminator::krisp::__cache_filename__
  export -f terminator::krisp::__render_markdown__
  export -f terminator::krisp::__human_size__
  export -f terminator::krisp::__migrate_legacy_cache__
  export -f terminator::krisp::__migrate_cache_names__
  export -f terminator::krisp::__usage__
  export -f terminator::krisp::list
  export -f terminator::krisp::get
  export -f terminator::krisp::cache
  export -f terminator::krisp::__completion__
}

# KCOV_EXCL_START
function terminator::krisp::__recall__ {
  unset TERMINATOR_KRISP_API_URL
  unset TERMINATOR_KRISP_CACHE_DIR

  export -fn terminator::krisp::__require_api_key__
  export -fn terminator::krisp::__require_curl__
  export -fn terminator::krisp::__require_jq__
  export -fn terminator::krisp::__api_get__
  export -fn terminator::krisp::__meetings__
  export -fn terminator::krisp::__resolve_meeting__
  export -fn terminator::krisp::__cache_candidates__
  export -fn terminator::krisp::__cache_path__
  export -fn terminator::krisp::__cache_write__
  export -fn terminator::krisp::__cache_read__
  export -fn terminator::krisp::__cache_entry_valid__
  export -fn terminator::krisp::__format_transcript__
  export -fn terminator::krisp::__cache_filename__
  export -fn terminator::krisp::__render_markdown__
  export -fn terminator::krisp::__human_size__
  export -fn terminator::krisp::__migrate_legacy_cache__
  export -fn terminator::krisp::__migrate_cache_names__
  export -fn terminator::krisp::__usage__
  export -fn terminator::krisp::list
  export -fn terminator::krisp::get
  export -fn terminator::krisp::cache
  export -fn terminator::krisp::__completion__
}
# KCOV_EXCL_STOP

terminator::__module__::export
