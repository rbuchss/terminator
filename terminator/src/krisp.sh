#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/color.sh"
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
  alias krisp-tag='terminator::krisp::tag'

  complete -F terminator::krisp::__completion__ krisp-list
  complete -F terminator::krisp::__completion__ krisp-get
  complete -F terminator::krisp::__completion__ krisp-cache
  complete -F terminator::krisp::__completion__ krisp-tag
}

function terminator::krisp::__disable__ {
  unalias krisp-list 2>/dev/null
  unalias krisp-get 2>/dev/null
  unalias krisp-cache 2>/dev/null
  unalias krisp-tag 2>/dev/null

  complete -r krisp-list 2>/dev/null
  complete -r krisp-get 2>/dev/null
  complete -r krisp-cache 2>/dev/null
  complete -r krisp-tag 2>/dev/null
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

# Validates a tag value: starts alphanumeric, then alphanumerics, dots,
# underscores, and hyphens. Logs and returns 1 on an invalid value.
# Usage: __tag_valid__ TAG
function terminator::krisp::__tag_valid__ {
  if ! [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    terminator::logger::error "krisp: invalid tag '$1'"
    return 1
  fi
}

# Validates a calendar date: YYYY-MM-DD shape, month 01-12, and a day
# within the month, leap-aware including the century rule.
# Usage: __date_valid__ DATE
function terminator::krisp::__date_valid__ {
  local __date_valid_result__
  terminator::krisp::__date_next__ "$1" __date_valid_result__
}

# Computes the next calendar day of a YYYY-MM-DD date in pure bash:
# month lengths and leap years including the century rule. Returns 1 for
# anything that is not a valid calendar date.
# Usage: __date_next__ DATE [OUTPUT_VAR]
function terminator::krisp::__date_next__ {
  local \
    __date_next_result__ \
    date="$1" \
    year \
    month \
    day \
    days

  [[ "${date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1

  year=$((10#${date:0:4}))
  month=$((10#${date:5:2}))
  day=$((10#${date:8:2}))

  case "${month}" in
    1 | 3 | 5 | 7 | 8 | 10 | 12) days=31 ;;
    4 | 6 | 9 | 11) days=30 ;;
    2)
      if ((year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))); then
        days=29
      else
        days=28
      fi
      ;;
    *) return 1 ;;
  esac

  ((day >= 1 && day <= days)) || return 1

  day=$((day + 1))
  if ((day > days)); then
    day=1
    month=$((month + 1))
    if ((month > 12)); then
      month=1
      year=$((year + 1))
    fi
  fi

  __date_next_result__="$(printf '%04d-%02d-%02d' "${year}" "${month}" "${day}")"

  case "$#" in
    2) printf -v "$2" '%s' "${__date_next_result__}" ;;
    *) echo "${__date_next_result__}" ;;
  esac
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
# newest first, optionally bounded by FROM/TO dates. The API's from/to
# params each include the whole bound day, so the query is a superset of
# the strict range and rows are filtered here to the strict range instead:
# started_at from FROM on, before TO. LIMIT counts in-range rows.
# Paginates via next_cursor when LIMIT exceeds the API's 100-per-request
# cap; LIMIT=0 means unbounded (page until the API is exhausted). Returns
# 1 on request or HTTP failure.
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
    kept \
    page \
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

    page="$(jq -c --arg from "${from}" --arg to "${to}" '
      .meetings[]? |
      select(
        (($from == "") or ((.started_at // "") >= $from)) and
        (($to == "") or ((.started_at // "") < $to))
      )
    ' <<<"${body}" 2>/dev/null)"
    count="$(jq '.meetings | length' <<<"${body}" 2>/dev/null)"
    [[ "${count}" =~ ^[0-9]+$ ]] || count=0
    kept=0
    if [[ -n "${page}" ]]; then
      lines+="${lines:+$'\n'}${page}"
      kept="$(jq -s 'length' <<<"${page}" 2>/dev/null)"
      [[ "${kept}" =~ ^[0-9]+$ ]] || kept=0
    fi
    remaining=$((remaining - kept))
    cursor="$(jq -r '.next_cursor // empty' <<<"${body}" 2>/dev/null)"

    # Nothing more to page through: no cursor, or an empty page. A page
    # whose rows all fall outside the range still pages on: rows are newest
    # first, so the outside-the-range ones lead and in-range rows can follow
    # on later pages.
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

# Collects the current-grammar cache entries whose filename timestamp
# falls in [SINCE, UNTIL): absolute paths, one per line, oldest first,
# written to OUTPUT_VAR as newline-joined text. Bounds are compared
# lexically against the timestamp segment and are normalized (first 19
# chars, colons to hyphens), so plain dates and ISO timestamps both work;
# an empty bound is open. Old-grammar filenames stay invisible until a
# krisp-cache view migrates them. Duplicate ids resolve to the lexically
# first filename. The compared shapes (digits and fixed separators) make
# the lexical order locale-independent.
# Usage: __cache_entries_in_range__ OUTPUT_VAR [SINCE] [UNTIL]
function terminator::krisp::__cache_entries_in_range__ {
  local \
    __cache_entries_in_range_out__="$1" \
    since="${2:-}" \
    until="${3:-}" \
    LC_ALL=C \
    entry \
    filename \
    ts \
    id \
    seen_ids="" \
    __cache_entries_in_range_result__=""

  since="${since:0:19}"
  since="${since//:/-}"
  until="${until:0:19}"
  until="${until//:/-}"

  for entry in "${TERMINATOR_KRISP_CACHE_DIR}"/*.md; do
    [[ -f "${entry}" ]] || continue
    filename="${entry##*/}"
    # Lexical grammar: <timestamp>Z__<id>__<slug>.md.
    [[ "${filename}" == *__*__*.md ]] || continue
    ts="${filename%%__*}"
    id="${filename#*__}"
    id="${id%%__*}"
    [[ -n "${id}" ]] || continue
    # Duplicate ids resolve to the lexically first filename; the glob
    # already walks oldest first.
    [[ ":${seen_ids}:" == *":${id}:"* ]] && continue
    seen_ids="${seen_ids}:${id}"
    # Strict bounds: from SINCE on, before UNTIL.
    if [[ -n "${since}" ]] && [[ "${ts}" < "${since}" ]]; then
      continue
    fi
    if [[ -n "${until}" ]] && [[ ! "${ts}" < "${until}" ]]; then
      continue
    fi
    __cache_entries_in_range_result__+="${__cache_entries_in_range_result__:+$'\n'}${entry}"
  done

  printf -v "${__cache_entries_in_range_out__}" '%s' "${__cache_entries_in_range_result__}"
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
# grammars. TAGS is an optional comma-joined list rendered into the
# frontmatter.
# Usage: __cache_write__ ID BODY [TAGS]
function terminator::krisp::__cache_write__ {
  local \
    id="$1" \
    body="$2" \
    tags="${3:-}" \
    filename \
    path \
    tmp \
    rendered \
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
  # The render's stdout form never takes TAGS, so render into a variable.
  if terminator::krisp::__render_markdown__ "${body}" rendered "${tags}" \
    && printf '%s\n' "${rendered}" >"${tmp}" && mv "${tmp}" "${path}"; then
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

# Reads a cache entry's tags: the comma-joined values of the frontmatter
# tags line, empty for a missing tags line and for legacy two-line
# headers. Only the frontmatter block is inspected, so a transcript line
# reading "tags: ..." never spoofs the field. Returns 1 when the block
# holds a malformed tags value: an unterminated block, two tags lines, or
# a value that is not a flow list of valid tags.
# Usage: __cache_entry_tags__ PATH [OUTPUT_VAR]
function terminator::krisp::__cache_entry_tags__ {
  local \
    __cache_entry_tags_result__="" \
    path="$1" \
    line \
    in_front=0 \
    closed=0 \
    found=0 \
    value=""

  [[ -r "${path}" ]] || return 1

  while IFS= read -r line; do
    if ((in_front == 0)); then
      [[ "${line}" == '---' ]] || break
      in_front=1
      continue
    fi
    if [[ "${line}" == '---' ]]; then
      closed=1
      break
    fi
    if [[ "${line}" == 'tags: '* ]]; then
      if ((found == 1)); then
        return 1
      fi
      value="${line#tags: }"
      found=1
    fi
  done <"${path}"

  # An unterminated frontmatter block is malformed.
  if ((in_front == 1 && closed == 0)); then
    return 1
  fi
  if ((found == 1)); then
    if [[ "${value}" == '[]' ]]; then
      value=""
    elif [[ "${value}" =~ ^\[[A-Za-z0-9][A-Za-z0-9._-]*(, [A-Za-z0-9][A-Za-z0-9._-]*)*\]$ ]]; then
      value="${value#[}"
      value="${value%]}"
    else
      return 1
    fi
  fi

  __cache_entry_tags_result__="${value}"

  case "$#" in
    2) printf -v "$2" '%s' "${__cache_entry_tags_result__}" ;;
    *) echo "${__cache_entry_tags_result__}" ;;
  esac
}

# Rewrites a cache entry's tags to exactly TAGS, a comma-joined list,
# sorted and deduped; an empty TAGS omits the tags line entirely, matching
# the render path. A frontmatter entry is rebuilt around its existing
# fields and body; a legacy two-line-header entry, its id marker ending
# line 2, is upgraded to frontmatter around a byte-unchanged body, with
# title and started_at synthesized from the old header lines and the
# title quoted like the render path. The entry is validated up front and
# the rewrite again before the atomic move. Returns 1 without writing on
# an unreadable or invalid entry or a failed write; the caller owns the
# error message.
# Usage: __cache_set_tags__ PATH ID TAGS
function terminator::krisp::__cache_set_tags__ {
  local \
    path="$1" \
    id="$2" \
    tags="$3" \
    body \
    line1 \
    line2 \
    title \
    started \
    escaped \
    front \
    rest \
    fields \
    kept \
    one \
    merged \
    new_body \
    tmp

  terminator::krisp::__cache_read__ "${path}" body
  if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
    return 1
  fi
  line1="${body%%$'\n'*}"
  line2="${body#*$'\n'}"
  line2="${line2%%$'\n'*}"

  # The new flow list: sorted, deduped, empty entries dropped.
  merged=""
  if [[ -n "${tags}" ]]; then
    while IFS= read -r one; do
      [[ -n "${one}" ]] || continue
      merged+="${merged:+, }${one}"
    done < <(printf '%s\n' "${tags//, /$'\n'}" | LC_ALL=C sort -u)
  fi

  if [[ "${line1}" == '---' ]]; then
    front="${body%%$'\n'---*}"
    if [[ "${body}" == *$'\n'---$'\n'* ]]; then
      rest="${body#*$'\n'---$'\n'}"
    else
      rest=""
    fi

    # Rebuild the fields without the old tags line; the new tags line is
    # inserted as the last field before the closing delimiter.
    fields="${front#*$'\n'}"
    kept=""
    while IFS= read -r one; do
      [[ "${one}" == 'tags: '* ]] && continue
      kept+="${kept:+$'\n'}${one}"
    done <<<"${fields}"

    new_body='---'
    [[ -n "${kept}" ]] && new_body+=$'\n'"${kept}"
    [[ -n "${merged}" ]] && new_body+=$'\n'"tags: [${merged}]"
    new_body+=$'\n''---'
    [[ -n "${rest}" ]] && new_body+=$'\n'"${rest}"
  elif [[ "${line1}" == '# '* ]] && [[ "${line2}" == *" (id ${id})" ]]; then
    # Legacy two-line header: upgrade to frontmatter around the
    # byte-unchanged body.
    title="${line1#\# }"
    title="${title% (id "${id}")}"
    [[ -n "${title}" ]] || title='(untitled)'
    started="${line2% (id "${id}")}"

    rest="${body#*$'\n'}"
    if [[ "${rest}" == *$'\n'* ]]; then
      rest="${rest#*$'\n'}"
    else
      rest=""
    fi

    # Match the render path's jq quoting for the title.
    escaped="${title//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"

    new_body="---
doc_type: transcript
id: ${id}
title: \"${escaped}\"
started_at: ${started}"
    [[ -n "${merged}" ]] && new_body+=$'\n'"tags: [${merged}]"
    new_body+=$'\n''---'
    [[ -n "${rest}" ]] && new_body+=$'\n'"${rest}"
  else
    return 1
  fi

  tmp="${path}.tmp.$$.$RANDOM"
  if printf '%s\n' "${new_body}" >"${tmp}" \
    && terminator::krisp::__cache_entry_valid__ "${id}" "$(cat "${tmp}")" \
    && mv "${tmp}" "${path}"; then
    return 0
  fi
  rm -f "${tmp}"
  return 1
}

# Merges TAG into a cache entry's tags in place. A frontmatter entry gets
# its tags flow list rewritten, with no write at all when TAG is already
# present, so re-running is idempotent. A legacy two-line-header entry,
# its id marker ending line 2, is upgraded to frontmatter around a
# byte-unchanged body. The rewrite itself is __cache_set_tags__; this
# wrapper validates the tag, the entry, and the existing tags value
# first. Returns 1 without writing on an invalid tag, an unreadable or
# invalid entry, a legacy header whose id marker does not end line 2, or
# a malformed tags value.
# Usage: __cache_retag__ PATH ID TAG
function terminator::krisp::__cache_retag__ {
  local \
    path="$1" \
    id="$2" \
    tag="$3" \
    body \
    existing \
    one \
    merged

  terminator::krisp::__tag_valid__ "${tag}" || return 1

  terminator::krisp::__cache_read__ "${path}" body
  if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
    terminator::logger::error "krisp: cannot retag '${path}'"
    return 1
  fi
  if ! terminator::krisp::__cache_entry_tags__ "${path}" existing; then
    terminator::logger::error "krisp: cannot retag '${path}'"
    return 1
  fi

  # Idempotent: TAG already present means no write at all. Legacy and
  # untagged entries read an empty list, so they fall through.
  while IFS= read -r one; do
    [[ "${one}" == "${tag}" ]] && return 0
  done <<<"${existing//, /$'\n'}"

  # Existing tags plus TAG; the rewrite sorts and dedupes.
  if [[ -n "${existing}" ]]; then
    merged="${existing}, ${tag}"
  else
    merged="${tag}"
  fi

  if ! terminator::krisp::__cache_set_tags__ "${path}" "${id}" "${merged}"; then
    terminator::logger::error "krisp: cannot retag '${path}'"
    return 1
  fi
}

# Removes TAG from a cache entry's tags in place, idempotently: a TAG
# absent from the entry, which includes legacy and untagged entries,
# writes nothing and returns 0. Removing the last tag omits the tags line
# entirely, matching the render path. Returns 1 without writing on an
# invalid tag, an unreadable or invalid entry, or a malformed tags value.
# Usage: __cache_untag__ PATH ID TAG
function terminator::krisp::__cache_untag__ {
  local \
    path="$1" \
    id="$2" \
    tag="$3" \
    body \
    existing \
    one \
    kept="" \
    found=0

  terminator::krisp::__tag_valid__ "${tag}" || return 1

  terminator::krisp::__cache_read__ "${path}" body
  if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
    terminator::logger::error "krisp: cannot untag '${path}'"
    return 1
  fi
  if ! terminator::krisp::__cache_entry_tags__ "${path}" existing; then
    terminator::logger::error "krisp: cannot untag '${path}'"
    return 1
  fi

  # The kept list is the existing tags minus TAG.
  while IFS= read -r one; do
    [[ -n "${one}" ]] || continue
    if [[ "${one}" == "${tag}" ]]; then
      found=1
    else
      kept+="${kept:+, }${one}"
    fi
  done <<<"${existing//, /$'\n'}"

  # Idempotent: TAG absent means no write at all.
  if ((found == 0)); then
    return 0
  fi

  if ! terminator::krisp::__cache_set_tags__ "${path}" "${id}" "${kept}"; then
    terminator::logger::error "krisp: cannot untag '${path}'"
    return 1
  fi
}

# Renames OLD to NEW in a cache entry's tags in place. Returns 0 when the
# entry was rewritten, 2 without writing when the entry does not carry
# OLD, and 1 without writing on an invalid tag, an unreadable or invalid
# entry, or a malformed tags value. A NEW already present elsewhere in
# the list leaves OLD simply dropped: the rewrite dedupes.
# Usage: __cache_rename_tag__ PATH ID OLD NEW
function terminator::krisp::__cache_rename_tag__ {
  local \
    path="$1" \
    id="$2" \
    old="$3" \
    new="$4" \
    body \
    existing \
    one \
    kept="" \
    found=0

  terminator::krisp::__tag_valid__ "${old}" || return 1
  terminator::krisp::__tag_valid__ "${new}" || return 1

  terminator::krisp::__cache_read__ "${path}" body
  if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
    terminator::logger::error "krisp: cannot rename tag in '${path}'"
    return 1
  fi
  if ! terminator::krisp::__cache_entry_tags__ "${path}" existing; then
    terminator::logger::error "krisp: cannot rename tag in '${path}'"
    return 1
  fi

  # The kept list replaces OLD with NEW wherever it appears.
  while IFS= read -r one; do
    [[ -n "${one}" ]] || continue
    if [[ "${one}" == "${old}" ]]; then
      found=1
      kept+="${kept:+, }${new}"
    else
      kept+="${kept:+, }${one}"
    fi
  done <<<"${existing//, /$'\n'}"

  # The entry does not carry OLD: skip without writing.
  if ((found == 0)); then
    return 2
  fi

  if ! terminator::krisp::__cache_set_tags__ "${path}" "${id}" "${kept}"; then
    terminator::logger::error "krisp: cannot rename tag in '${path}'"
    return 1
  fi
}

# Collects the distinct tags across a set of cache entries, one per line,
# LC_ALL=C sorted, written to OUTPUT_VAR. An empty SELECTION means the
# whole library. Legacy and untagged entries contribute nothing; a
# malformed tags value is skipped like the cache view does.
# Usage: __tag_vocabulary__ OUTPUT_VAR [SELECTION]
function terminator::krisp::__tag_vocabulary__ {
  local \
    __tag_vocabulary_out__="$1" \
    selection="${2:-}" \
    entry \
    tags \
    __tag_vocabulary_result__=""

  if [[ -z "${selection}" ]]; then
    terminator::krisp::__cache_entries_in_range__ selection
  fi

  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    terminator::krisp::__cache_entry_tags__ "${entry}" tags || tags=""
    [[ -n "${tags}" ]] || continue
    __tag_vocabulary_result__+="${__tag_vocabulary_result__:+$'\n'}${tags//, /$'\n'}"
  done <<<"${selection}"

  if [[ -n "${__tag_vocabulary_result__}" ]]; then
    __tag_vocabulary_result__="$(printf '%s\n' "${__tag_vocabulary_result__}" | LC_ALL=C sort -u)"
  fi

  printf -v "${__tag_vocabulary_out__}" '%s' "${__tag_vocabulary_result__}"
}

# Applies a comma-joined TAGS list to every entry in SELECTION (absolute
# paths, one per line), the id from filename segment 2: VERB add merges
# each tag via __cache_retag__, VERB rm removes each via __cache_untag__.
# A failed entry logs the helper's error and processing continues; the
# entry does not count. Prints the processed count in the house count
# style; returns 1 when any entry failed.
# Usage: __tag_apply__ VERB TAGS SELECTION
function terminator::krisp::__tag_apply__ {
  local \
    verb="$1" \
    tags="$2" \
    selection="$3" \
    entry \
    filename \
    id \
    one \
    ok \
    count=0 \
    failure=0

  case "${verb}" in
    add | rm) ;;
    *) return 2 ;;
  esac

  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    filename="${entry##*/}"
    id="${filename#*__}"
    id="${id%%__*}"
    ok=1
    while IFS= read -r one; do
      [[ -n "${one}" ]] || continue
      if [[ "${verb}" == add ]]; then
        terminator::krisp::__cache_retag__ "${entry}" "${id}" "${one}" || ok=0
      else
        terminator::krisp::__cache_untag__ "${entry}" "${id}" "${one}" || ok=0
      fi
    done <<<"${tags//, /$'\n'}"
    if ((ok)); then
      count=$((count + 1))
    else
      failure=1
    fi
  done <<<"${selection}"

  if [[ "${verb}" == add ]]; then
    if ((count == 1)); then
      echo "Tagged 1 transcript with '${tags}'"
    elif ((count > 1)); then
      echo "Tagged ${count} transcripts with '${tags}'"
    fi
  else
    if ((count == 1)); then
      echo "Removed '${tags}' from 1 transcript"
    elif ((count > 1)); then
      echo "Removed '${tags}' from ${count} transcripts"
    fi
  fi

  ((failure == 0))
}

# Renames OLD to NEW across every current-grammar cache entry, library
# wide. The library vocabulary is checked first: an OLD no entry carries
# is a notice and exit 1 with nothing written. Each entry is renamed in
# place via __cache_rename_tag__; an entry not carrying OLD is a normal
# skip. Prints the renamed count in the house count style; returns 1 when
# any rename failed.
# Usage: __tag_rename__ OLD NEW
function terminator::krisp::__tag_rename__ {
  local \
    old="$1" \
    new="$2" \
    vocabulary \
    one \
    entries \
    entry \
    filename \
    id \
    found=0 \
    rc \
    count=0 \
    failure=0

  terminator::krisp::__tag_valid__ "${old}" || return 1
  terminator::krisp::__tag_valid__ "${new}" || return 1

  terminator::krisp::__tag_vocabulary__ vocabulary
  while IFS= read -r one; do
    [[ "${one}" == "${old}" ]] && found=1
  done <<<"${vocabulary}"
  if ((found == 0)); then
    terminator::logger::error "no cached transcript carries '${old}'"
    return 1
  fi

  terminator::krisp::__cache_entries_in_range__ entries
  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    filename="${entry##*/}"
    id="${filename#*__}"
    id="${id%%__*}"
    terminator::krisp::__cache_rename_tag__ "${entry}" "${id}" "${old}" "${new}"
    rc=$?
    case "${rc}" in
      0) count=$((count + 1)) ;;
      2) ;; # The entry does not carry OLD: a normal skip.
      *) failure=1 ;;
    esac
  done <<<"${entries}"

  if ((count == 1)); then
    echo "Renamed '${old}' to '${new}' in 1 transcript"
  elif ((count > 1)); then
    echo "Renamed '${old}' to '${new}' in ${count} transcripts"
  fi

  ((failure == 0))
}

# Fetches one meeting into the cache for a range pull. Guards must already
# have passed. Expected skips (transcription still processing, an empty
# transcript) log a warning and return 1; unexpected failures (HTTP, curl,
# write) log an error and return 2. A successful fetch writes the entry and
# stores its absolute path in OUTPUT_VAR.
# Usage: __range_fetch__ OUTPUT_VAR ID TITLE TAGS
function terminator::krisp::__range_fetch__ {
  local \
    __range_fetch_out__="$1" \
    id="$2" \
    title="$3" \
    tags="$4" \
    body \
    code="" \
    path

  if ! terminator::krisp::__api_get__ body code "/meetings/${id}" \
    'fields=title,started_at,duration,status,transcript'; then
    terminator::logger::error "krisp: skipped '${title}' (id ${id:0:8}): fetch transcript failed"
    return 2
  fi

  if ((code == 409)); then
    # The status changed between list and fetch.
    terminator::logger::warning "krisp: skipped '${title}' (id ${id:0:8}): transcription still processing"
    return 1
  fi

  if ((code != 200)); then
    terminator::logger::error "krisp: skipped '${title}' (id ${id:0:8}): fetch transcript failed (HTTP ${code})"
    return 2
  fi

  if ! jq -e '(.transcript.segments // []) | length > 0' <<<"${body}" >/dev/null 2>&1; then
    terminator::logger::warning "krisp: skipped '${title}' (id ${id:0:8}): no transcript in response"
    return 1
  fi

  if ! terminator::krisp::__cache_write__ "${id}" "${body}" "${tags}" \
    || ! terminator::krisp::__cache_path__ "${id}" path; then
    terminator::logger::error "krisp: skipped '${title}' (id ${id:0:8}): failed to write cache entry"
    return 2
  fi

  printf -v "${__range_fetch_out__}" '%s' "${path}"
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
# block, the title, a blank line, then the formatted transcript. TAGS is
# an optional comma-joined list rendered as the last frontmatter field,
# sorted, deduped, and omitted when empty; a tagless render is
# byte-identical with or without the argument. The cache entry and
# krisp-get stdout are byte-identical.
# Usage: __render_markdown__ BODY [OUTPUT_VAR] [TAGS]
function terminator::krisp::__render_markdown__ {
  local \
    __render_markdown_result__ \
    __render_markdown_header__ \
    tags="${3:-}"

  __render_markdown_header__="$(jq -r --arg tags "${tags}" '
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
      (if $tags != "" then
        ($tags | split(",") | map(gsub("^ +| +$"; "")) | map(select(length > 0))
          | unique
          | if length > 0 then "tags: [" + join(", ") + "]" else empty end)
      else empty end),
      "---",
      "",
      "# \(.title // "(untitled)")"
  ' <<<"$1" 2>/dev/null)"

  __render_markdown_result__="${__render_markdown_header__}

$(terminator::krisp::__format_transcript__ "$1")"

  case "$#" in
    2 | 3) printf -v "$2" '%s' "${__render_markdown_result__}" ;;
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

# Serves krisp-get --json: resolves the target when ID is empty (TOKEN
# cache-first, or the most recent meeting through one API list call when
# both are empty), fetches it live, and prints the raw response. The cache
# is read only to resolve the target, never written, so the fetch is
# always live and the API guards always apply.
# Usage: __json_pull__ ID TOKEN
function terminator::krisp::__json_pull__ {
  local \
    id="$1" \
    token="$2" \
    meetings \
    body \
    code
  # --json always fetches live, so the guards always apply.
  terminator::krisp::__require_api_key__ || return 1
  terminator::krisp::__require_curl__ || return 1
  terminator::krisp::__require_jq__ || return 1

  if [[ -z "${id}" ]]; then
    if [[ -n "${token}" ]]; then
      # Both "not found" (1) and "ambiguous" (2) already logged their error.
      terminator::krisp::__resolve_meeting__ id "${token}" || return 1
    else
      terminator::krisp::__meetings__ meetings 1 || return 1
      id="$(jq -r '.[0].id // empty' <<<"${meetings}")"
      if [[ -z "${id}" ]]; then
        terminator::logger::error 'no meetings found'
        return 1
      fi
    fi
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

  printf '%s\n' "${body}"
}

# Serves krisp-get's single-target mode: the PREFIX meeting when ID is
# pre-resolved, else TOKEN resolves it, else the most recent meeting when
# both are empty. Prints the target's absolute cache path. A pre-resolved
# ID serves fully offline; an empty ID resolves after the key, curl, and
# jq guards: TOKEN cache-first, a live list only when nothing is cached,
# no TOKEN through one API list call. A cached target then serves with no
# detail fetch. REFRESH (0 or 1) forces a refetch, preserving existing
# tags and merging TAG into them.
# Usage: __single_pull__ ID TOKEN REFRESH TAG
function terminator::krisp::__single_pull__ {
  local \
    id="$1" \
    token="$2" \
    refresh="$3" \
    tag="$4" \
    meetings \
    path \
    body \
    code \
    tags \
    existing
  # Single-target mode: PREFIX, or the most recent meeting via --latest.
  if [[ -z "${id}" ]]; then
    terminator::krisp::__require_api_key__ || return 1
    terminator::krisp::__require_curl__ || return 1
    terminator::krisp::__require_jq__ || return 1

    if [[ -n "${token}" ]]; then
      terminator::krisp::__resolve_meeting__ id "${token}" || return 1
    else
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
  if ((refresh == 0)) && terminator::krisp::__cache_path__ "${id}" path; then
    terminator::krisp::__cache_read__ "${path}" body

    if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
      terminator::logger::error "cache entry for '${id}' is corrupt; re-fetch with --refresh"
      return 1
    fi

    if [[ -n "${tag}" ]] && ! terminator::krisp::__cache_retag__ "${path}" "${id}" "${tag}"; then
      return 1
    fi

    printf '%s\n' "${path}"
    return 0
  fi

  terminator::krisp::__require_api_key__ || return 1
  terminator::krisp::__require_curl__ || return 1
  terminator::krisp::__require_jq__ || return 1

  # Existing tags are read before the overwrite and merged with any
  # --tag, so a refresh never drops them. Only an otherwise-valid entry
  # refuses the refresh over an unreadable tags line; a corrupt one is
  # overwritten, keeping re-fetch the documented corruption recovery.
  tags="${tag}"
  if terminator::krisp::__cache_path__ "${id}" path; then
    terminator::krisp::__cache_read__ "${path}" body
    if terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
      if ! terminator::krisp::__cache_entry_tags__ "${path}" existing; then
        terminator::logger::error "krisp: cannot refresh '${path}': tags line is unreadable or malformed"
        return 1
      fi
      [[ -n "${existing}" ]] && tags="${existing}${tag:+, ${tag}}"
    fi
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

  # An empty transcript is never cached; only --refresh could recover it.
  if ! jq -e '(.transcript.segments // []) | length > 0' <<<"${body}" >/dev/null 2>&1; then
    terminator::logger::error "no transcript in response for meeting '${id}'"
    return 1
  fi

  terminator::krisp::__cache_write__ "${id}" "${body}" "${tags}" || return 1

  if ! terminator::krisp::__cache_path__ "${id}" path; then
    terminator::logger::error "cache entry for meeting '${id}' vanished after write"
    return 1
  fi
  printf '%s\n' "${path}"
}

# Pulls the API meetings in ROWS (TSV lines of id, status, title) into the
# cache and writes the newline-joined absolute cache paths, feed order, to
# OUTPUT_VAR. Cached entries serve unless REFRESH (0 or 1) forces refetches;
# existing tags are preserved and TAG merged into every targeted entry.
# Expected skips log a notice; returns 1 when any unexpected failure
# occurred.
# Usage: __rows_pull__ OUTPUT_VAR ROWS REFRESH TAG
function terminator::krisp::__rows_pull__ {
  local \
    __rows_pull_out__="$1" \
    rows="$2" \
    refresh="$3" \
    tag="$4" \
    id \
    status \
    title \
    seen_ids="" \
    failure=0 \
    path \
    body \
    existing \
    tags \
    new_path \
    fetch_rc \
    __rows_pull_result__=""

  # API rows, feed order; the collected paths keep feed order and the caller
  # sorts.
  while IFS=$'\t' read -r id status title; do
    [[ -n "${id}" ]] || continue
    seen_ids=":${id}${seen_ids}"
    tags="${tag}"

    if terminator::krisp::__cache_path__ "${id}" path; then
      if ((refresh == 0)) || [[ "${status}" != "ready" ]]; then
        # Serve the cached copy: an entry the API no longer lists, or one
        # whose transcription is not ready, cannot be refetched. A readable
        # entry that fails validation is corrupt and is never silently
        # re-fetched.
        terminator::krisp::__cache_read__ "${path}" body

        if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
          terminator::logger::error "krisp: skipped '${path}': cache entry is corrupt"
          failure=1
          continue
        fi

        if ((refresh == 1)); then
          terminator::logger::warning "krisp: serving cached '${title}' (id ${id:0:8}): transcription still processing"
        fi

        if [[ -n "${tag}" ]] && ! terminator::krisp::__cache_retag__ "${path}" "${id}" "${tag}"; then
          failure=1
        fi

        __rows_pull_result__+="${__rows_pull_result__:+$'\n'}${path}"
        continue
      fi

      # Refetch: existing tags are read before the overwrite and merged with
      # any --tag. Only an otherwise-valid entry skips the refetch over
      # an unreadable tags line; a corrupt one is overwritten, keeping
      # re-fetch the documented corruption recovery.
      terminator::krisp::__cache_read__ "${path}" body
      if terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
        if ! terminator::krisp::__cache_entry_tags__ "${path}" existing; then
          terminator::logger::error "krisp: skipped '${path}': tags line is unreadable or malformed"
          failure=1
          continue
        fi
        [[ -n "${existing}" ]] && tags="${existing}${tag:+, ${tag}}"
      fi
    elif [[ "${status}" != "ready" ]]; then
      terminator::logger::warning "krisp: skipped '${title}' (id ${id:0:8}): transcription still processing"
      continue
    fi

    fetch_rc=0
    terminator::krisp::__range_fetch__ new_path "${id}" "${title}" "${tags}" || fetch_rc=$?
    if ((fetch_rc == 0)); then
      __rows_pull_result__+="${__rows_pull_result__:+$'\n'}${new_path}"
    elif ((fetch_rc == 2)); then
      failure=1
    fi
  done <<<"${rows}"

  printf -v "${__rows_pull_out__}" '%s' "${__rows_pull_result__}"
  ((failure == 0))
}

# Serves krisp-get's range mode (--on, --since/--until): pulls every
# meeting in [SINCE, UNTIL) into the cache and prints each entry's
# absolute cache path, oldest first. The in-range set is the union of
# API-listed meetings and cached in-range entries, so a cached entry the
# API no longer lists still prints. Fetches only meetings missing from
# the cache unless REFRESH (0 or 1) forces refetches; existing tags are
# preserved and TAG merged into every targeted entry. Expected skips
# log a notice; returns 1 when any unexpected failure occurred.
# Usage: __range_pull__ SINCE UNTIL REFRESH TAG
function terminator::krisp::__range_pull__ {
  local \
    since="$1" \
    until="$2" \
    refresh="$3" \
    tag="$4" \
    meetings \
    cached_entries \
    rows \
    id \
    seen_ids="" \
    paths="" \
    failure=0 \
    path \
    body \
    filename
  # Range mode: the API is always consulted, and the in-range set is the union
  # of listed meetings and cached in-range entries, so a cached entry the API
  # no longer lists still prints.
  terminator::krisp::__require_api_key__ || return 1
  terminator::krisp::__require_curl__ || return 1
  terminator::krisp::__require_jq__ || return 1

  terminator::krisp::__meetings__ meetings 0 "${since}" "${until}" || return 1

  terminator::krisp::__cache_entries_in_range__ cached_entries "${since}" "${until}"

  rows="$(jq -r '.[] | [(.id // ""), (.status // "ready"), (.title // "(untitled)")] | @tsv' <<<"${meetings}")"

  terminator::krisp::__rows_pull__ paths "${rows}" "${refresh}" "${tag}" || failure=1

  # API ids the rows loop handled, re-derived from the same TSV with the
  # same skip-empty rule, so union exclusion matches the loop exactly.
  while IFS=$'\t' read -r id _; do
    [[ -n "${id}" ]] || continue
    seen_ids=":${id}${seen_ids}"
  done <<<"${rows}"

  # Cached in-range entries the API no longer lists: the cache is the library
  # source of truth, so they still print.
  while IFS= read -r path; do
    [[ -n "${path}" ]] || continue
    filename="${path##*/}"
    id="${filename#*__}"
    id="${id%%__*}"
    [[ -n "${id}" ]] || continue
    [[ ":${seen_ids}:" == *":${id}:"* ]] && continue

    terminator::krisp::__cache_read__ "${path}" body

    if ! terminator::krisp::__cache_entry_valid__ "${id}" "${body}"; then
      terminator::logger::error "krisp: skipped '${path}': cache entry is corrupt"
      failure=1
      continue
    fi

    if [[ -n "${tag}" ]] && ! terminator::krisp::__cache_retag__ "${path}" "${id}" "${tag}"; then
      failure=1
    fi

    paths+="${paths:+$'\n'}${path}"
  done <<<"${cached_entries}"

  # Absolute paths, oldest first.
  [[ -n "${paths}" ]] && printf '%s\n' "${paths}" | LC_ALL=C sort
  ((failure == 0))
}

# Pulls the API meetings picked in an interactive multi-select fzf into the
# cache and prints each entry's absolute cache path, oldest first. The feed
# is the 100 newest API meetings; picked meetings missing from the cache
# fetch incrementally while REFRESH (0 or 1) forces refetches, preserving
# existing tags and merging TAG into every targeted entry. Esc, ctrl-c, or
# an empty pick cancels with nothing fetched; an empty feed is a valid empty
# result. Returns 1 when any unexpected failure occurred.
# Usage: __picker_pull__ REFRESH TAG
function terminator::krisp::__picker_pull__ {
  local \
    refresh="$1" \
    tag="$2" \
    feed \
    count \
    tsv \
    pulled \
    failure=0

  terminator::krisp::__require_api_key__ || return 1
  terminator::krisp::__require_curl__ || return 1
  terminator::krisp::__require_jq__ || return 1

  terminator::krisp::__meetings__ feed 100 || return 1
  count="$(jq 'length' <<<"${feed}")"
  if ((count == 0)); then
    terminator::logger::info 'krisp: no meetings to pull'
    return 0
  fi

  if ! terminator::krisp::__pick_meetings__ tsv "${feed}"; then
    # Esc, ctrl-c, or an empty pick: the pick precedes every fetch, so
    # nothing was fetched and nothing prints.
    terminator::logger::info 'krisp: cancelled'
    return 0
  fi

  terminator::krisp::__rows_pull__ pulled "${tsv}" "${refresh}" "${tag}" || failure=1

  # Absolute paths, oldest first; an all-not-ready pick prints nothing.
  [[ -n "${pulled}" ]] && printf '%s\n' "${pulled}" | LC_ALL=C sort
  ((failure == 0))
}

# Selects cache entries for the krisp-cache views and the krisp-tag
# filter selectors: entries in [SINCE, UNTIL) by filename timestamp,
# narrowed to entries tagged exactly FILTER_TAG when it is set. Writes
# the selected absolute paths, oldest first, to OUTPUT_VAR.
# Usage: __cache_select__ OUTPUT_VAR SINCE UNTIL FILTER_TAG
function terminator::krisp::__cache_select__ {
  local \
    __cache_select_out__="$1" \
    since="$2" \
    until="$3" \
    filter_tag="$4" \
    __cache_select_result__="" \
    filtered="" \
    entry \
    tags \
    matched \
    one

  terminator::krisp::__cache_entries_in_range__ __cache_select_result__ "${since}" "${until}"

  # --tag matches tag values exactly, never as a substring.
  if [[ -n "${filter_tag}" ]]; then
    filtered=""
    while IFS= read -r entry; do
      [[ -n "${entry}" ]] || continue
      terminator::krisp::__cache_entry_tags__ "${entry}" tags || tags=""
      matched=0
      while IFS= read -r one; do
        [[ "${one}" == "${filter_tag}" ]] && matched=1
      done <<<"${tags//, /$'\n'}"
      if ((matched == 1)); then
        filtered+="${filtered:+$'\n'}${entry}"
      fi
    done <<<"${__cache_select_result__}"
    __cache_select_result__="${filtered}"
  fi

  printf -v "${__cache_select_out__}" '%s' "${__cache_select_result__}"
}

# Serves krisp-cache --rm: resolves PREFIX to exactly one cached
# transcript and removes it, matching both filename grammars plus a
# legacy .json. Returns 1 with an error when nothing or an ambiguous set
# matches.
# Usage: __cache_rm__ PREFIX
function terminator::krisp::__cache_rm__ {
  local \
    token="$1" \
    candidates=() \
    entry

  while IFS= read -r entry; do
    candidates+=("${entry}")
  done < <(terminator::krisp::__cache_candidates__ "${token}")

  if ((${#candidates[@]} == 0)); then
    terminator::logger::error "no cached transcript matches '${token}'"
    return 1
  elif ((${#candidates[@]} > 1)); then
    terminator::logger::error "ambiguous meeting prefix '${token}': ${candidates[*]}"
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
}

# Serves krisp-cache --clear: removes every cached transcript, including
# stale partial writes from interrupted cache writes, and prints the
# count.
# Usage: __cache_clear__
function terminator::krisp::__cache_clear__ {
  local \
    entry \
    count=0

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
}

# Reports whether the default cache view should color its tags token: yes
# when stdout is a terminal, the terminal is not dumb, and NO_COLOR is unset
# or empty. Usage: __color_auto__
function terminator::krisp::__color_auto__ {
  [[ -t 1 && "${TERM}" != dumb && -z "${NO_COLOR}" ]]
}

# Renders the view's [tag1, tag2] token. COLOR=0 keeps it plain; COLOR=1
# wraps it in the configured color and a reset. The color comes from
# TERMINATOR_KRISP_TAG_COLOR (verbatim escape), TERMINATOR_KRISP_TAG_COLOR_CODE
# (SGR params), or a cyan default. Usage: __tag_token__ TAGS COLOR [OUTPUT_VAR]
function terminator::krisp::__tag_token__ {
  local __token__="[$1]"
  local color="$2"

  if ((color)); then
    if [[ -n "${TERMINATOR_KRISP_TAG_COLOR}" ]]; then
      __token__="${TERMINATOR_KRISP_TAG_COLOR}${__token__}$(terminator::color::off_bare)"
    else
      __token__="$(terminator::color::code_bare "${TERMINATOR_KRISP_TAG_COLOR_CODE:-36m}")${__token__}$(terminator::color::off_bare)"
    fi
  fi

  case "$#" in
    3) printf -v "$3" '%s' "${__token__}" ;;
    2) printf '%s' "${__token__}" ;;
    *) terminator::logger::error 'invalid # of args' ;;
  esac
}

# Renders the view's row lines: one per selected entry (timestamp, id, a
# right-aligned size, a [tag1, tag2] token when tags exist, slug), with no
# header or footer. COLOR=1 renders the tags token colored. An empty
# selection renders nothing.
# Usage: __cache_view_rows__ SELECTION [COLOR]
function terminator::krisp::__cache_view_rows__ {
  local \
    selected="$1" \
    color="${2:-0}" \
    entry \
    filename \
    when \
    id \
    slug \
    bytes \
    size \
    tags \
    token \
    width=0 \
    i

  local -a \
    heads=() \
    sizes=() \
    tails=()

  # Filenames carry the started_at timestamp with colons traded for hyphens;
  # show it as the ISO form the filename derives from: YYYY-MM-DDTHH:MMZ.
  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    filename="${entry##*/}"
    when="${filename:0:10}T${filename:11:2}:${filename:14:2}Z"
    id="${filename#*__}"
    id="${id%%__*}"
    slug="${filename#*__*__}"
    slug="${slug%.md}"
    bytes="$(wc -c <"${entry}")"
    terminator::krisp::__human_size__ "${bytes}" size
    ((${#size} > width)) && width="${#size}"
    terminator::krisp::__cache_entry_tags__ "${entry}" tags || tags=""
    heads+=("${when}  ${id}")
    sizes+=("${size}")
    if [[ -n "${tags}" ]]; then
      terminator::krisp::__tag_token__ "${tags}" "${color}" token
      tails+=("${token}  ${slug}")
    else
      tails+=("${slug}")
    fi
  done <<<"${selected}"

  # Sizes pad right up to the widest one so the columns after them line up.
  for i in "${!sizes[@]}"; do
    printf '%s  %*s  %s\n' "${heads[$i]}" "${width}" "${sizes[$i]}" "${tails[$i]}"
  done
}

# Serves the krisp-cache default view: the cache dir line, one line per
# selected entry (timestamp, id, a right-aligned size, a [tag1, tag2] token
# when tags exist, slug), and the total count and size. COLOR=1 renders the
# tags token colored. An empty selection prints the header lines only.
# Usage: __cache_view__ SELECTION [COLOR]
function terminator::krisp::__cache_view__ {
  local \
    selected="$1" \
    color="${2:-0}" \
    entry \
    count=0 \
    total=0

  # Footer aggregates: one row per selected entry, bytes summed.
  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    count=$((count + 1))
    total=$((total + $(wc -c <"${entry}")))
  done <<<"${selected}"

  echo "Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}"

  terminator::krisp::__cache_view_rows__ "${selected}" "${color}"

  if ((count == 1)); then
    echo "1 transcript, $(terminator::krisp::__human_size__ "${total}") total"
  else
    echo "${count} transcripts, $(terminator::krisp::__human_size__ "${total}") total"
  fi
}

# Opens the transcript picker over SELECTION (absolute cache paths, one per
# line): the plain view rows, no header or footer, latest first, in fzf
# with multi-mark. A zero fzf exit accepts the marked rows, or the
# highlighted row on plain enter with none marked: each accepted row's
# id (field 2 of the row) resolves back to its cache path and the
# newline-joined paths, in the order fzf printed them, are written to
# OUTPUT_VAR, returning 0. A no-match filter (fzf exit 1) writes empty
# output and returns 0: a no-op round. Esc or ctrl-c (fzf 130), or any
# other nonzero fzf exit, cancels with the output discarded: returns 1.
# A row whose id resolves to no cache entry logs an error and returns 2.
# Usage: __pick_entries__ OUTPUT_VAR SELECTION
function terminator::krisp::__pick_entries__ {
  local \
    __pick_entries_out__="$1" \
    entries="$2" \
    reversed \
    pick_rc \
    chosen \
    row \
    when \
    id \
    path \
    __pick_entries_result__=""

  # Latest first: filenames start with the timestamp, so the reversed feed
  # leads with the newest entry.
  reversed="$(printf '%s\n' "${entries}" | LC_ALL=C sort -r)"

  pick_rc=0
  chosen="$(terminator::krisp::__cache_view_rows__ "${reversed}" 0 \
    | fzf --multi --header='tab: mark, enter: continue, esc: end session')" || pick_rc=$?

  if ((pick_rc > 1)); then
    # esc, ctrl-c (130), or an fzf error: cancelled, the output discarded.
    printf -v "${__pick_entries_out__}" '%s' ''
    return 1
  fi
  if [[ -z "${chosen}" ]]; then
    # A no-match filter (fzf exit 1): a no-op round.
    printf -v "${__pick_entries_out__}" '%s' ''
    return 0
  fi

  while IFS= read -r row; do
    [[ -n "${row}" ]] || continue
    # Rows join fields with double spaces; read collapses them.
    read -r when id _ <<<"${row}"
    if ! terminator::krisp::__cache_path__ "${id}" path; then
      terminator::logger::error "krisp: no cached transcript for id '${id}'"
      printf -v "${__pick_entries_out__}" '%s' ''
      return 2
    fi
    __pick_entries_result__+="${__pick_entries_result__:+$'\n'}${path}"
  done <<<"${chosen}"

  printf -v "${__pick_entries_out__}" '%s' "${__pick_entries_result__}"
}

# Opens the meeting picker over MEETINGS_JSON (an API meetings array,
# newest first): the krisp-list row grammar in fzf with multi-mark. A
# feed meeting without an id renders no row. A zero fzf exit accepts the
# marked rows, or the highlighted row on plain enter with none marked:
# each accepted row's id (field 2 of the row) maps back to its feed
# meeting and the newline-joined TSV id, status, title rows, feed order,
# are written to OUTPUT_VAR, returning 0. An accepted row whose id
# matches no feed meeting (a title continuation line) is skipped with a
# notice and the rest proceed. When every accepted row is unmappable,
# OUTPUT_VAR is left empty, returning 0. An empty fzf output or any
# nonzero fzf exit cancels with fzf's output discarded: returns 1.
# Usage: __pick_meetings__ OUTPUT_VAR MEETINGS_JSON
function terminator::krisp::__pick_meetings__ {
  local \
    __pick_meetings_out__="$1" \
    meetings="$2" \
    rows \
    pick_rc \
    chosen \
    row \
    when \
    id \
    feed \
    feed_id \
    entry \
    found \
    marked="" \
    __pick_meetings_result__=""

  # The krisp-list row grammar; meetings without an id render no row.
  rows="$(jq -r '
    .[] |
    select((.id // "") != "") |
    (.started_at // "") as $st |
    (if $st == "" then "-" else ($st[0:10] + "T" + $st[11:16] + "Z") end) as $when |
    (if (.status // "ready") != "ready" then "  [\(.status)]" else "" end) as $status |
    "\($when)  \(.id)  \(.title // "(untitled)")\($status)"
  ' <<<"${meetings}")"

  pick_rc=0
  chosen="$(printf '%s\n' "${rows}" \
    | fzf --multi --header='tab: mark, enter: pull, esc: cancel')" || pick_rc=$?
  if ((pick_rc != 0)); then
    # esc, ctrl-c (130), a no-match filter (exit 1), or an fzf error:
    # cancelled, the output discarded.
    printf -v "${__pick_meetings_out__}" '%s' ''
    return 1
  fi
  if [[ -z "${chosen}" ]]; then
    printf -v "${__pick_meetings_out__}" '%s' ''
    return 1
  fi

  # The feed in TSV, the same id normalization as the range rows.
  feed="$(jq -r '.[] | [(.id // ""), (.status // "ready"), (.title // "(untitled)")] | @tsv' <<<"${meetings}")"

  while IFS= read -r row; do
    [[ -n "${row}" ]] || continue
    # Rows join fields with double spaces; read collapses them.
    read -r when id _ <<<"${row}"
    found=0
    while IFS=$'\t' read -r feed_id _; do
      [[ -n "${feed_id}" ]] || continue
      [[ "${feed_id}" == "${id}" ]] || continue
      found=1
      break
    done <<<"${feed}"
    if ((found == 0)); then
      terminator::logger::warning "krisp: skipped '${row}': no meeting matches the row"
      continue
    fi
    [[ ":${marked}:" == *":${id}:"* ]] || marked=":${id}${marked}"
  done <<<"${chosen}"

  # Feed order: walk the feed and keep the accepted ids.
  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    feed_id="${entry%%$'\t'*}"
    [[ -n "${feed_id}" ]] || continue
    [[ ":${marked}:" == *":${feed_id}:"* ]] || continue
    __pick_meetings_result__+="${__pick_meetings_result__:+$'\n'}${entry}"
  done <<<"${feed}"

  printf -v "${__pick_meetings_out__}" '%s' "${__pick_meetings_result__}"
}

# Opens the tag picker over VOCABULARY (one tag per line) with HEADER:
# fzf with multi-mark and --print-query, so the first output line is the
# typed query and the rest the accepted tags (the marked rows, or the
# highlighted row on plain enter with none marked). A zero fzf exit
# accepts: the query splits on commas and whitespace, empty tolerated,
# and joins with the accepted tags into the comma-joined, deduped tag
# list written to OUTPUT_VAR. fzf also exits 1 on enter with no match
# but still prints the typed query: a non-empty query is the typed-tag
# accept (an empty one cancels). Any other nonzero fzf exit (esc, ctrl-c
# 130; error 2) cancels with the output discarded: returns 1. Every
# token is validated before any mutation: an invalid one logs the tag
# error and returns 2.
# Usage: __pick_tags__ OUTPUT_VAR VOCABULARY HEADER
function terminator::krisp::__pick_tags__ {
  local \
    __pick_tags_out__="$1" \
    vocabulary="$2" \
    header="$3" \
    pick_rc \
    chosen \
    query \
    marked \
    one \
    seen="" \
    __pick_tags_result__=""

  local -a tokens=()

  pick_rc=0
  chosen="$(printf '%s\n' "${vocabulary}" \
    | fzf --multi --print-query --header="${header}")" || pick_rc=$?

  if ((pick_rc == 1)); then
    # Enter with no match: the typed query is the accept, nothing is
    # marked; an empty query is a cancel.
    query="${chosen%%$'\n'*}"
    marked=""
    if [[ -z "${query}" ]]; then
      printf -v "${__pick_tags_out__}" '%s' ''
      return 1
    fi
  elif ((pick_rc != 0)); then
    # esc, ctrl-c, or an fzf error: cancelled, the output discarded.
    printf -v "${__pick_tags_out__}" '%s' ''
    return 1
  else
    # Line 1 is the query; the rest are the accepted tags.
    query="${chosen%%$'\n'*}"
    if [[ "${chosen}" == *$'\n'* ]]; then
      marked="${chosen#*$'\n'}"
    else
      marked=""
    fi
  fi

  # Query tokens split on commas and whitespace; duplicates keep their
  # first occurrence.
  read -r -a tokens <<<"${query//,/ }"
  while IFS= read -r one; do
    [[ -n "${one}" ]] || continue
    if ! terminator::krisp::__tag_valid__ "${one}"; then
      printf -v "${__pick_tags_out__}" '%s' ''
      return 2
    fi
    [[ ":${seen}:" == *":${one}:"* ]] && continue
    seen="${seen}:${one}"
    __pick_tags_result__+="${__pick_tags_result__:+, }${one}"
  done < <(
    printf '%s\n' "${tokens[@]}"
    printf '%s\n' "${marked}"
  )

  printf -v "${__pick_tags_out__}" '%s' "${__pick_tags_result__}"
}

# Runs the krisp-tag picker session: entry rounds until esc. Each round
# reopens the entry picker over SELECTION (absolute paths, one per line),
# never filtered between rounds, so every entry stays listed and rows
# re-render with freshly applied tags. Esc or ctrl-c at the entry picker
# ends the session, earlier rounds kept; a no-match filter is a no-op
# round. With no TAGS pre-supplied, the tags picker follows: VERB rm
# offers the round's picked entries' tags (an empty vocabulary reopens
# the entry picker), add offers the whole library. Esc or ctrl-c at the
# tags picker cancels the round back to the entry picker. Applies each
# round via __tag_apply__ and continues on a failed round. Returns 0
# when the session ended cleanly, 1 when any round failed, an invalid
# tag, or an entry id resolved to no cache entry.
# Usage: __tag_session__ VERB TAGS SELECTION
function terminator::krisp::__tag_session__ {
  local \
    verb="$1" \
    tags="$2" \
    selection="$3" \
    round_selected \
    round_tags \
    vocabulary \
    header \
    pick_rc \
    session_failure=0

  while true; do
    pick_rc=0
    terminator::krisp::__pick_entries__ round_selected "${selection}" || pick_rc=$?
    case "${pick_rc}" in
      1)
        # Esc or ctrl-c: the session ends, earlier rounds kept.
        terminator::logger::info 'krisp: cancelled'
        return "${session_failure}"
        ;;
      2)
        # An id resolving to no cache entry: an error round.
        return 1
        ;;
    esac
    if [[ -z "${round_selected}" ]]; then
      # A no-match filter: a no-op round.
      continue
    fi

    round_tags="${tags}"
    if [[ -z "${round_tags}" ]]; then
      if [[ "${verb}" == rm ]]; then
        terminator::krisp::__tag_vocabulary__ vocabulary "${round_selected}"
        if [[ -z "${vocabulary}" ]]; then
          terminator::logger::info 'the picked entries carry no tags'
          continue
        fi
        header='type or tab tags to remove: enter: continue, esc: cancel'
      else
        terminator::krisp::__tag_vocabulary__ vocabulary
        header='type or tab tags to add: enter: continue, esc: cancel'
      fi

      pick_rc=0
      terminator::krisp::__pick_tags__ round_tags "${vocabulary}" "${header}" || pick_rc=$?
      case "${pick_rc}" in
        0) ;;
        2)
          # An invalid tag: an error round.
          return 1
          ;;
        *)
          # Esc or ctrl-c at the tags picker: the round is cancelled and
          # the entry picker reopens.
          continue
          ;;
      esac
      if [[ -z "${round_tags}" ]]; then
        # An empty tags result: a cancelled round.
        continue
      fi
    fi

    terminator::krisp::__tag_apply__ "${verb}" "${round_tags}" "${round_selected}" || session_failure=1
  done
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
    --on DATE                 List a single day (YYYY-MM-DD)
    --since DATE              Only meetings from DATE on (YYYY-MM-DD or ISO)
    --until DATE              Only meetings before DATE (YYYY-MM-DD or ISO)
    -h, --help                Show this help

  A date range without --limit lists every meeting in the range. The
  typical flow: krisp-list --on DATE to find the day, then krisp-get
  --on DATE to pull it.
USAGE_TEXT
      ;;
    krisp-get)
      cat <<USAGE_TEXT
Usage: krisp-get [OPTIONS] [PREFIX]

  Pull Krisp meeting transcripts into the cache and print each target's
  absolute cache path, one per line, oldest first. With no PREFIX and no
  dates, opens an interactive multi-select picker over the 100 newest
  meetings; esc, ctrl-c, or an empty pick cancels with nothing fetched.
  A cached PREFIX resolves and serves fully offline. The picker and
  --latest resolve the target through the API list; a cached target
  then serves with no detail fetch.

  Arguments:
    PREFIX                    Meeting id prefix (from krisp-list or cache)

  Options:
    --latest                  Pull the most recent meeting, no picker
    --on DATE                 Pull a single day (YYYY-MM-DD)
    --since DATE              Pull meetings from DATE on (YYYY-MM-DD)
    --until DATE              Pull meetings before DATE (YYYY-MM-DD)
    --refresh                 Force refetches, preserving existing tags
    -t, --tag TAG             Merge TAG into every targeted entry, cached
                              and fetched alike; with no addressing form
                              it composes with the picker
    --json [PREFIX]           Print one raw API response instead; always
                              fetches live, reading the cache only to
                              resolve the target
    -h, --help                Show this help

  PREFIX, --latest, --on, and --since/--until are exclusive addressing
  forms. A range pull fetches only meetings missing from the cache;
  --refresh refetches everything in range. Meetings still processing
  are skipped with a stderr notice and do not fail the run.

  Tags are managed with krisp-tag.

  The typical flow: krisp-list --on DATE to find the day, krisp-get
  --on DATE to pull it, then paste the printed paths into Claude or
  open them with cat or less.

  Cache entries are markdown files named YYYY-MM-DDTHH-MM-SSZ__id__slug.md,
  so the cache dir doubles as a browsable transcript library. Each entry
  opens with a YAML frontmatter block (doc_type, id, title, and started_at,
  plus duration, language, and tags when set), then the title heading, then
  one line per spoken segment.

  Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}
USAGE_TEXT
      ;;
    krisp-cache)
      cat <<USAGE_TEXT
Usage: krisp-cache [OPTIONS]

  Show the offline transcript library, oldest first. The default view
  prints the cache dir and one line per entry, with a [tag1, tag2]
  token when tags exist. Old filename grammars and legacy .json entries
  are migrated on view. Works fully offline: no API, no key.

  Options:
    --path                    Print absolute entry paths only, one per
                              line, oldest first
    --on DATE                 Only entries from DATE (YYYY-MM-DD)
    --since DATE              Only entries from DATE on (YYYY-MM-DD or ISO)
    --until DATE              Only entries before DATE (YYYY-MM-DD or ISO)
    --tag TAG                 Only entries tagged TAG (exact match)
    --rm PREFIX               Remove one cached transcript (meeting id
                              prefix)
    --clear                   Remove every cached transcript
    --color                   Color the tags token even when piped
    --no-color                Keep the tags token plain even on a terminal
    -h, --help                Show this help

  A filter matching nothing is a valid empty result. --rm and --clear
  are exclusive with the other modes, and --color with --no-color.
  Cached transcripts are regenerable from the API, so neither removal
  asks for confirmation, but both delete the only local copy: a later
  fetch re-creates the entry.

  Tags are managed with krisp-tag.

  The tags token renders colored when stdout is a terminal and NO_COLOR
  is unset or empty; --color and --no-color force that on or off. The
  color defaults to cyan and can be overridden with
  TERMINATOR_KRISP_TAG_COLOR (verbatim escape) or
  TERMINATOR_KRISP_TAG_COLOR_CODE (SGR params, e.g. 38;5;69m).

  Cache dir: ${TERMINATOR_KRISP_CACHE_DIR}
USAGE_TEXT
      ;;
    krisp-tag)
      cat <<USAGE_TEXT
Usage: krisp-tag [OPTIONS] [TAG...]

  Tag cached transcripts in bulk: add TAGs (the default), remove them
  with --rm, or rename a tag across the whole library with --rename.
  Picker-first: missing pieces are picked with fzf; -x/--exec skips
  every picker. Works fully offline: no API, no key.

  Arguments:
    TAG                       Tags to add or remove; typed and picked tags
                              merge, deduped

  Options:
    -x, --exec                Non-interactive: no pickers; TAGs and a
                              selector required
    --rm                      Remove TAGs instead of adding them
    --rename [OLD:NEW]        Rename OLD to NEW library-wide; with the
                              value omitted, OLD and NEW are picked
    --id PREFIX               One cached transcript, by meeting id prefix
    --on DATE                 Only entries from DATE (YYYY-MM-DD)
    --since DATE              Only entries from DATE on (YYYY-MM-DD or ISO)
    --until DATE              Only entries before DATE (YYYY-MM-DD or ISO)
    --tag TAG                 Only entries tagged TAG (exact match)
    -h, --help                Show this help

  Interactive flow: rounds of picking entries (selectors narrow the
  list, newest first) and, when no TAGs were given, typing or picking
  tags; each applied round reopens the entry picker with fresh rows
  until esc or ctrl-c ends the session, earlier rounds kept. --rm
  offers only the tags the picked entries carry; esc or ctrl-c at the
  tags picker cancels that round back to the entry picker.

  Selectors narrow the interactive list and define the -x batch: --id
  takes exactly one entry and is exclusive with the others; the date and
  --tag filters intersect. A selector matching nothing is an empty list
  interactively (a notice, exit 0) and an error with -x (exit 1).

  --rename is library-wide: it takes no TAGs and no selectors, and
  renaming to a tag entries already carry merges the two. krisp-tag --rm
  removes tags; krisp-cache --rm removes entries.

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
# --on DATE lists a single day; --since/--until list a date range.
function terminator::krisp::list {
  local \
    limit=10 \
    limit_set=0 \
    since="" \
    until="" \
    on="" \
    date \
    meetings \
    count

  while (($# != 0)); do
    case "$1" in
      -l | --limit)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-list --limit requires a number'
          return 1
        fi
        limit="$1"
        limit_set=1
        ;;
      --since)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-list --since requires a date'
          return 1
        fi
        since="$1"
        ;;
      --until)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-list --until requires a date'
          return 1
        fi
        until="$1"
        ;;
      --on)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-list --on requires a date'
          return 1
        fi
        on="$1"
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

  # --on DATE is a single-day range: from DATE on, before the next day.
  if [[ -n "${on}" ]]; then
    if [[ -n "${since}" || -n "${until}" ]]; then
      terminator::logger::error 'krisp-list --on is exclusive with --since and --until'
      return 1
    fi
    since="${on}"
    if ! terminator::krisp::__date_next__ "${on}" until; then
      terminator::logger::error "krisp-list invalid date: '${on}' (expected YYYY-MM-DD)"
      return 1
    fi
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
    (.id // "?") as $id |
    (.started_at // "") as $st |
    (if $st == "" then "-" else ($st[0:10] + "T" + $st[11:16] + "Z") end) as $when |
    (if (.status // "ready") != "ready" then "  [\(.status)]" else "" end) as $status |
    "\($when)  \($id)  \(.title // "(untitled)")\($status)"
  ' <<<"${meetings}"
}

# Pulls Krisp meeting transcripts into the cache and prints each target's
# absolute cache path, one per line, oldest first. With no PREFIX, opens an
# interactive multi-select picker over the 100 newest API meetings and pulls
# the picked ones; esc, ctrl-c, or an empty pick cancels with nothing
# fetched. --latest targets the most recent meeting instead; the API list
# resolves the target, and a cached one serves with no detail fetch.
# --on DATE pulls a single day; --since/--until pull a date range (strict
# bounds: from SINCE on, before UNTIL). A range pull fetches only meetings
# missing from the cache, unioning the API list with cached in-range
# entries so an entry the API no longer lists still prints.
# --refresh forces refetches while preserving each entry's existing tags.
# -t/--tag TAG merges a tag into every targeted entry. --json prints one raw
# API response instead: live fetch, the cache read only to resolve the target.
function terminator::krisp::get {
  local \
    token="" \
    json=0 \
    refresh=0 \
    tag="" \
    since="" \
    until="" \
    on="" \
    latest=0 \
    forms=0 \
    id="" \
    date \
    entry \
    candidates=()

  while (($# != 0)); do
    case "$1" in
      --json)
        json=1
        ;;
      --refresh)
        refresh=1
        ;;
      --latest)
        latest=1
        ;;
      -t | --tag)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-get --tag requires a tag value'
          return 1
        fi
        tag="$1"
        ;;
      --since)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-get --since requires a date'
          return 1
        fi
        since="$1"
        ;;
      --until)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-get --until requires a date'
          return 1
        fi
        until="$1"
        ;;
      --on)
        shift
        if [[ -z "${1:-}" ]]; then
          terminator::logger::error 'krisp-get --on requires a date'
          return 1
        fi
        on="$1"
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

  # PREFIX, --latest, --on, and --since/--until are exclusive addressing
  # forms.
  [[ -n "${token}" ]] && ((forms += 1))
  ((latest == 1)) && ((forms += 1))
  [[ -n "${on}" ]] && ((forms += 1))
  [[ -n "${since}" || -n "${until}" ]] && ((forms += 1))
  if ((forms > 1)); then
    terminator::logger::error 'krisp-get PREFIX, --latest, --on, and --since/--until are exclusive addressing forms'
    return 1
  fi

  if ((json == 1)); then
    if ((refresh == 1)); then
      terminator::logger::error 'krisp-get --json and --refresh are contradictory'
      return 1
    fi
    if [[ -n "${tag}" ]]; then
      terminator::logger::error 'krisp-get --json and --tag are contradictory'
      return 1
    fi
    if ((latest == 1)); then
      terminator::logger::error 'krisp-get --json and --latest are contradictory'
      return 1
    fi
    if [[ -n "${on}" || -n "${since}" || -n "${until}" ]]; then
      terminator::logger::error 'krisp-get --json and a date range are contradictory'
      return 1
    fi
  fi

  # --on DATE is a single-day range: from DATE on, before the next day.
  if [[ -n "${on}" ]]; then
    since="${on}"
    if ! terminator::krisp::__date_next__ "${on}" until; then
      terminator::logger::error "krisp-get invalid date: '${on}' (expected YYYY-MM-DD)"
      return 1
    fi
  fi

  for date in "${since}" "${until}"; do
    [[ -z "${date}" ]] && continue
    if ! terminator::krisp::__date_valid__ "${date}"; then
      terminator::logger::error "krisp-get invalid date: '${date}' (expected YYYY-MM-DD)"
      return 1
    fi
  done

  if [[ -n "${tag}" ]] && ! terminator::krisp::__tag_valid__ "${tag}"; then
    return 1
  fi

  # Offline fast path: a unique cached prefix resolves before any guard or
  # fetch, so cached meetings work with KRISP_API_KEY unset.
  if [[ -n "${token}" ]] && ((refresh == 0)); then
    while IFS= read -r entry; do
      candidates+=("${entry}")
    done < <(terminator::krisp::__cache_candidates__ "${token}")
    if ((${#candidates[@]} == 1)); then
      id="${candidates[0]}"
    elif ((${#candidates[@]} > 1)); then
      # Ambiguity is determinable offline; never mask it behind the guards.
      terminator::logger::error "ambiguous meeting prefix '${token}': ${candidates[*]}"
      return 1
    fi
  fi

  if ((json == 1)); then
    terminator::krisp::__json_pull__ "${id}" "${token}"
    return
  fi

  # PREFIX and --latest are single-target pulls; --latest keeps the prior
  # bare-get behavior and targets the most recent meeting.
  if [[ -n "${token}" ]] || ((latest == 1)); then
    terminator::krisp::__single_pull__ "${id}" "${token}" "${refresh}" "${tag}"
    return
  fi

  if [[ -z "${since}" && -z "${until}" ]]; then
    # Bare get is an interactive multi-select picker over recent meetings.
    if ! terminator::command::exists fzf; then
      terminator::logger::error 'krisp-get requires fzf for its picker; pass --latest to target the most recent meeting without a picker'
      return 1
    fi
    if [[ ! -t 0 ]]; then
      terminator::logger::error 'krisp-get requires a terminal for its picker; pass --latest to target the most recent meeting without a picker'
      return 1
    fi
    terminator::krisp::__picker_pull__ "${refresh}" "${tag}"
    return
  fi

  terminator::krisp::__range_pull__ "${since}" "${until}" "${refresh}" "${tag}"
}

# Manages the offline transcript library. The default view prints the
# cache dir and one line per entry, oldest first, with a [tag1, tag2]
# token between size and slug when tags exist; --path prints absolute
# entry paths only, nothing else. --since/--until/--on/--tag filter both
# views by filename timestamp or exact tag value; a filter matching
# nothing is a valid empty result. The tags token renders colored when
# stdout is a terminal and NO_COLOR is unset or empty; --color and
# --no-color force that on or off, and TERMINATOR_KRISP_TAG_COLOR or
# TERMINATOR_KRISP_TAG_COLOR_CODE overrides the default cyan. Old
# filename grammars migrate on view before selection in every mode but
# --clear, and legacy .json entries in the view and --path modes. --rm
# PREFIX removes a single entry; --clear removes them all. Cached
# transcripts are regenerable from the API, so neither removal asks for
# confirmation, but both delete the only local copy: a later fetch
# re-creates the entry. Tags are managed with krisp-tag. Entirely
# offline: no API, no key; jq only for the legacy .json migration.
function terminator::krisp::cache {
  local \
    clear=0 \
    rm_token="" \
    path_mode=0 \
    colorize=-1 \
    filter_tag="" \
    since="" \
    until="" \
    on="" \
    notices_stdout=1 \
    one \
    notice \
    migrated=0 \
    selected=""

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
      --path)
        path_mode=1
        ;;
      --since)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-cache --since requires a date'
          return 1
        }
        since="$2"
        shift
        ;;
      --until)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-cache --until requires a date'
          return 1
        }
        until="$2"
        shift
        ;;
      --on)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-cache --on requires a date'
          return 1
        }
        on="$2"
        shift
        ;;
      --tag)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-cache --tag requires a tag value'
          return 1
        }
        filter_tag="$2"
        shift
        ;;
      --color)
        if ((colorize == 0)); then
          terminator::logger::error 'krisp-cache --color and --no-color are mutually exclusive'
          return 1
        fi
        colorize=1
        ;;
      --no-color)
        if ((colorize == 1)); then
          terminator::logger::error 'krisp-cache --color and --no-color are mutually exclusive'
          return 1
        fi
        colorize=0
        ;;
      -h | --help)
        terminator::krisp::__usage__ krisp-cache
        return 0
        ;;
      -*)
        terminator::logger::error "krisp-cache unknown option: '$1'"
        return 1
        ;;
      *)
        terminator::logger::error "krisp-cache unexpected argument: '$1'"
        return 1
        ;;
    esac
    shift
  done

  if ((clear == 1)) && [[ -n "${rm_token}" ]]; then
    terminator::logger::error 'krisp-cache --clear and --rm are mutually exclusive'
    return 1
  fi

  if ((clear == 1)) || [[ -n "${rm_token}" ]]; then
    if ((path_mode == 1)) \
      || [[ -n "${filter_tag}" ]] \
      || [[ -n "${since}${until}${on}" ]]; then
      terminator::logger::error 'krisp-cache --rm and --clear are exclusive with --path and the filters'
      return 1
    fi
  fi

  if [[ -n "${on}" ]]; then
    if [[ -n "${since}" ]] || [[ -n "${until}" ]]; then
      terminator::logger::error 'krisp-cache --on is exclusive with --since and --until'
      return 1
    fi
    if ! terminator::krisp::__date_next__ "${on}" until; then
      terminator::logger::error "krisp-cache invalid date: '${on}' (expected YYYY-MM-DD)"
      return 1
    fi
    since="${on}"
  fi

  # ISO timestamps are accepted as bounds: the in-range compare normalizes
  # them, so only the date portion is validated here.
  for one in "${since}" "${until}"; do
    [[ -n "${one}" ]] || continue
    if [[ ! "${one}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]] \
      || ! terminator::krisp::__date_valid__ "${one:0:10}"; then
      terminator::logger::error "krisp-cache invalid date: '${one}' (expected YYYY-MM-DD)"
      return 1
    fi
  done

  if [[ -n "${filter_tag}" ]] && ! terminator::krisp::__tag_valid__ "${filter_tag}"; then
    return 1
  fi

  # The --path mode keeps its stdout to the paths: migration notices move
  # to stderr there; the default view keeps them.
  if ((path_mode == 1)); then
    notices_stdout=0
  fi

  # Old-grammar filenames are migrated before --rm resolution so a prefix
  # still matches; --clear skips it.
  if ((clear == 0)); then
    terminator::krisp::__migrate_cache_names__ migrated
    if ((migrated > 0)); then
      notice="Migrated ${migrated} cache filename(s) to the current grammar"
      if ((notices_stdout == 1)); then
        echo "${notice}"
      else
        terminator::logger::info "${notice}"
      fi
    fi
  fi

  if [[ -n "${rm_token}" ]]; then
    terminator::krisp::__cache_rm__ "${rm_token}"
    return
  fi

  if ((clear == 1)); then
    terminator::krisp::__cache_clear__
    return
  fi

  if ! terminator::command::exists jq; then
    terminator::logger::warning 'skipping legacy cache migration: jq is required'
  else
    terminator::krisp::__migrate_legacy_cache__ migrated
    if ((migrated > 0)); then
      if ((migrated == 1)); then
        notice='Migrated 1 legacy cache entry'
      else
        notice="Migrated ${migrated} legacy cache entries"
      fi
      if ((notices_stdout == 1)); then
        echo "${notice}"
      else
        terminator::logger::info "${notice}"
      fi
    fi
  fi

  terminator::krisp::__cache_select__ selected "${since}" "${until}" "${filter_tag}"

  if ((path_mode == 1)); then
    [[ -n "${selected}" ]] && printf '%s\n' "${selected}"
    return 0
  fi

  # A filter matching nothing is a valid empty result: nothing printed.
  if [[ -n "${filter_tag}${since}${until}${on}" ]] && [[ -z "${selected}" ]]; then
    return 0
  fi

  # The early-return modes above never reach a tags token, so the tty check
  # only runs when the default view is actually about to render.
  if ((colorize < 0)); then
    if terminator::krisp::__color_auto__; then
      colorize=1
    else
      colorize=0
    fi
  fi

  terminator::krisp::__cache_view__ "${selected}" "${colorize}"
}

# Picker-first bulk tagging of cached transcripts: adds the TAG positionals
# (the default verb), removes them with --rm, or renames one tag across the
# whole library with --rename. Selectors (--id, --on, --since, --until,
# --tag) narrow the interactive entry picker and define the -x/--exec batch.
# A piece the invocation leaves out is picked with fzf: entries first, then,
# when no TAGs were given, tags (the --rm vocabulary is the picked entries'
# tags; the add vocabulary is the whole library). A valued --rename has
# nothing to pick and runs direct in both modes. Cancelling a picker
# applies nothing: esc or ctrl-c at the entry picker ends the session,
# earlier rounds kept; esc or ctrl-c at the tags picker cancels the round.
# Works fully offline: no API, no key.
function terminator::krisp::tag {
  local \
    rm=0 \
    rename_seen=0 \
    rename_value="" \
    exec_mode=0 \
    id_prefix="" \
    since="" \
    until="" \
    on="" \
    filter_tag="" \
    tags="" \
    selected="" \
    vocabulary="" \
    old="" \
    new="" \
    pick_rc \
    one \
    resolved \
    migrated=0 \
    verb

  local -a candidates=()

  while (($# != 0)); do
    case "$1" in
      -x | --exec)
        exec_mode=1
        ;;
      --rm)
        rm=1
        ;;
      --rename)
        rename_seen=1
        # A value is consumed only when non-empty and not dash-prefixed, so
        # --rename -h and --rename -x stay flag positions.
        if [[ -n "${2:-}" && "${2:-}" != -* ]]; then
          rename_value="$2"
          shift
        fi
        ;;
      --id)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-tag --id requires a meeting id prefix'
          return 1
        }
        id_prefix="$2"
        shift
        ;;
      --on)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-tag --on requires a date'
          return 1
        }
        on="$2"
        shift
        ;;
      --since)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-tag --since requires a date'
          return 1
        }
        since="$2"
        shift
        ;;
      --until)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-tag --until requires a date'
          return 1
        }
        until="$2"
        shift
        ;;
      --tag)
        [[ -n "${2:-}" ]] || {
          terminator::logger::error 'krisp-tag --tag requires a tag value'
          return 1
        }
        filter_tag="$2"
        shift
        ;;
      -h | --help)
        terminator::krisp::__usage__ krisp-tag
        return 0
        ;;
      -*)
        terminator::logger::error "krisp-tag unknown option: '$1'"
        return 1
        ;;
      *)
        terminator::krisp::__tag_valid__ "$1" || return 1
        tags+="${tags:+, }$1"
        ;;
    esac
    shift
  done

  # Rename is vocabulary-wide: no TAGs, no --rm, no selectors.
  if ((rename_seen == 1)); then
    if ((rm == 1)) || [[ -n "${tags}" ]] || [[ -n "${id_prefix}${since}${until}${on}${filter_tag}" ]]; then
      terminator::logger::error 'krisp-tag --rename is exclusive with --rm, TAGs, and the selectors'
      return 1
    fi
    if [[ -n "${rename_value}" ]]; then
      old="${rename_value%%:*}"
      new="${rename_value#*:}"
      if [[ -z "${old}" || -z "${new}" || "${old}" == "${new}" ]]; then
        terminator::logger::error "krisp-tag --rename expects OLD:NEW (got '${rename_value}')"
        return 1
      fi
    fi
  fi

  # -x never opens a picker, so every piece must already be present; a
  # valued --rename picks nothing in either mode.
  if ((exec_mode == 1)); then
    if ((rename_seen == 1)); then
      if [[ -z "${rename_value}" ]]; then
        terminator::logger::error 'krisp-tag -x with --rename requires OLD:NEW'
        return 1
      fi
    else
      if [[ -z "${tags}" ]]; then
        terminator::logger::error 'krisp-tag -x requires at least one TAG'
        return 1
      fi
      if [[ -z "${id_prefix}${since}${until}${on}${filter_tag}" ]]; then
        terminator::logger::error 'krisp-tag -x requires a selector: --id, --on, --since, --until, or --tag'
        return 1
      fi
    fi
  fi

  if [[ -n "${id_prefix}" ]] && [[ -n "${since}${until}${on}${filter_tag}" ]]; then
    terminator::logger::error 'krisp-tag --id is exclusive with --on, --since, --until, and --tag'
    return 1
  fi

  if [[ -n "${on}" ]]; then
    if [[ -n "${since}" ]] || [[ -n "${until}" ]]; then
      terminator::logger::error 'krisp-tag --on is exclusive with --since and --until'
      return 1
    fi
    if ! terminator::krisp::__date_next__ "${on}" until; then
      terminator::logger::error "krisp-tag invalid date: '${on}' (expected YYYY-MM-DD)"
      return 1
    fi
    since="${on}"
  fi

  # ISO timestamps are accepted as bounds: the in-range compare normalizes
  # them, so only the date portion is validated here.
  for one in "${since}" "${until}"; do
    [[ -n "${one}" ]] || continue
    if [[ ! "${one}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]] \
      || ! terminator::krisp::__date_valid__ "${one:0:10}"; then
      terminator::logger::error "krisp-tag invalid date: '${one}' (expected YYYY-MM-DD)"
      return 1
    fi
  done

  if [[ -n "${filter_tag}" ]] && ! terminator::krisp::__tag_valid__ "${filter_tag}"; then
    return 1
  fi

  # A library-wide mutation surface must see every entry: migrate old
  # filename grammars and legacy .json entries before any selection or
  # dispatch; stdout keeps the summary, so the notices go to stderr.
  terminator::krisp::__migrate_cache_names__ migrated
  if ((migrated > 0)); then
    terminator::logger::info "Migrated ${migrated} cache filename(s) to the current grammar"
  fi

  if ! terminator::command::exists jq; then
    terminator::logger::warning 'skipping legacy cache migration: jq is required'
  else
    terminator::krisp::__migrate_legacy_cache__ migrated
    if ((migrated > 0)); then
      if ((migrated == 1)); then
        terminator::logger::info 'Migrated 1 legacy cache entry'
      else
        terminator::logger::info "Migrated ${migrated} legacy cache entries"
      fi
    fi
  fi

  if ((rm == 1)); then
    verb='rm'
  else
    verb='add'
  fi

  # Rename runs library-wide before any selection: valued runs direct, a
  # valueless one picks OLD and NEW from the vocabulary.
  if ((rename_seen == 1)); then
    if [[ -n "${rename_value}" ]]; then
      terminator::krisp::__tag_rename__ "${old}" "${new}"
      return
    fi

    terminator::krisp::__tag_vocabulary__ vocabulary
    if [[ -z "${vocabulary}" ]]; then
      terminator::logger::info 'the library carries no tags'
      return 0
    fi

    if ! terminator::command::exists fzf; then
      terminator::logger::error 'krisp-tag requires fzf for its pickers; pass -x/--exec to run non-interactively'
      return 1
    fi
    if [[ ! -t 0 ]]; then
      terminator::logger::error 'krisp-tag requires a terminal for its pickers; pass -x/--exec to run non-interactively'
      return 1
    fi

    if ! old="$(printf '%s\n' "${vocabulary}" \
      | fzf --header='pick a tag to rename: enter: continue, esc: cancel')"; then
      terminator::logger::info 'krisp: cancelled'
      return 0
    fi
    if [[ -z "${old}" ]]; then
      terminator::logger::info 'krisp: cancelled'
      return 0
    fi

    pick_rc=0
    new="$(printf '%s\n' "${vocabulary}" | grep -v -x -F "${old}" \
      | fzf --print-query --header='type or pick the new tag: enter: continue, esc: cancel')" || pick_rc=$?
    if ((pick_rc == 1)); then
      # Enter with no match: the typed query is the new tag; an empty one
      # is a cancel.
      new="${new%%$'\n'*}"
      if [[ -z "${new}" ]]; then
        terminator::logger::info 'krisp: cancelled'
        return 0
      fi
    elif ((pick_rc != 0)); then
      terminator::logger::info 'krisp: cancelled'
      return 0
    else
      # Line 1 is the typed query; an empty one takes the picked line.
      one="${new%%$'\n'*}"
      if [[ -n "${one}" ]]; then
        new="${one}"
      else
        new="${new#*$'\n'}"
        new="${new%%$'\n'*}"
      fi
    fi
    if [[ -z "${new}" ]]; then
      terminator::logger::info 'krisp: cancelled'
      return 0
    fi
    if [[ "${new}" == "${old}" ]]; then
      terminator::logger::error "krisp-tag --rename expects OLD:NEW (got '${old}:${new}')"
      return 1
    fi
    terminator::krisp::__tag_valid__ "${new}" || return 1
    terminator::krisp::__tag_rename__ "${old}" "${new}"
    return
  fi

  # Selector resolution: --id pins exactly one entry, the filters intersect.
  if [[ -n "${id_prefix}" ]]; then
    while IFS= read -r one; do
      [[ -n "${one}" ]] && candidates+=("${one}")
    done < <(terminator::krisp::__cache_candidates__ "${id_prefix}")
    if ((${#candidates[@]} > 1)); then
      terminator::logger::error "ambiguous meeting prefix '${id_prefix}': ${candidates[*]}"
      return 1
    fi
    if ((${#candidates[@]} == 1)); then
      # `resolved`, not `entry`: __cache_path__ locals `entry`.
      terminator::krisp::__cache_path__ "${candidates[0]}" resolved
      selected="${resolved}"
    elif ((exec_mode == 1)); then
      terminator::logger::error "no cached transcript matches '${id_prefix}'"
      return 1
    fi
  else
    terminator::krisp::__cache_select__ selected "${since}" "${until}" "${filter_tag}"
  fi

  # An empty feed never opens a picker: interactively it is an empty pick
  # list (a notice); under -x a mutation selector matching nothing is
  # almost always a typo (a notice, exit 1).
  if [[ -z "${selected}" ]]; then
    if ((exec_mode == 1)); then
      terminator::logger::info 'no cached transcripts match the selector'
      return 1
    fi
    terminator::logger::info 'no cached transcripts to tag'
    return 0
  fi

  if ((exec_mode == 1)); then
    terminator::krisp::__tag_apply__ "${verb}" "${tags}" "${selected}"
    return
  fi

  # Guards run exactly when a picker is about to open, and each failure
  # names the non-interactive switch: never a silent degrade.
  if ! terminator::command::exists fzf; then
    terminator::logger::error 'krisp-tag requires fzf for its pickers; pass -x/--exec to run non-interactively'
    return 1
  fi
  if [[ ! -t 0 ]]; then
    terminator::logger::error 'krisp-tag requires a terminal for its pickers; pass -x/--exec to run non-interactively'
    return 1
  fi

  terminator::krisp::__tag_session__ "${verb}" "${tags}" "${selected}"
}

################################################################################
# Completion
################################################################################

# Tab completion for krisp-list/get/cache/tag: each command's flags on a
# dash, and offline value completions where they exist (never an API call).
# krisp-get earns cached ids before any addressing form; krisp-tag completes
# ids after --id and the tag vocabulary everywhere else.
function terminator::krisp::__completion__ {
  local \
    cur \
    prev \
    word \
    completion \
    vocabulary \
    flags \
    i=1 \
    seen_form=0 \
    seen_positional=0

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  if [[ "${cur}" == -* ]]; then
    case "${COMP_WORDS[0]}" in
      krisp-list) flags='-l --limit --on --since --until -h --help' ;;
      krisp-get) flags='--latest --since --until --on --json --refresh --tag -t -h --help' ;;
      krisp-cache) flags='--rm --clear --path --since --until --on --tag --color --no-color -h --help' ;;
      krisp-tag) flags='-x --exec --rm --rename --id --on --since --until --tag -h --help' ;;
      *) flags='-h --help' ;;
    esac

    COMPREPLY=()
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(compgen -W "${flags}" -- "${cur}")
    return
  fi

  COMPREPLY=()

  # krisp-list and krisp-cache take no positionals and no completable
  # values: their dates, tags, and the --rm PREFIX complete nothing.
  case "${COMP_WORDS[0]}" in
    krisp-list | krisp-cache)
      return
      ;;
    krisp-tag)
      case "${prev}" in
        --on | --since | --until)
          # Dates have nothing to complete.
          return
          ;;
        --id)
          while IFS='' read -r completion; do
            COMPREPLY+=("${completion}")
          done < <(terminator::krisp::__cache_candidates__ "${cur}")
          return
          ;;
        *)
          # TAG positionals and the --tag, --rename, and --rm slots all
          # complete from the library vocabulary.
          terminator::krisp::__tag_vocabulary__ vocabulary
          while IFS='' read -r completion; do
            COMPREPLY+=("${completion}")
          done < <(compgen -W "${vocabulary}" -- "${cur}")
          return
          ;;
      esac
      ;;
    krisp-get)
      case "${prev}" in
        -t | --tag | --on | --since | --until)
          # The tag and date slots have nothing to complete.
          return
          ;;
      esac
      ;;
    *)
      return
      ;;
  esac

  # Walk the earlier words, skipping the values of value-taking flags, to
  # see whether a PREFIX positional is still meaningful here.
  while ((i < COMP_CWORD)); do
    word="${COMP_WORDS[i]}"
    case "${word}" in
      --since | --until | --on)
        seen_form=1
        i=$((i + 2))
        continue
        ;;
      --latest)
        # An addressing form that takes no value.
        seen_form=1
        ;;
      -t | --tag)
        i=$((i + 2))
        continue
        ;;
      -*)
        : # Other flags take no positional slot.
        ;;
      *)
        seen_positional=1
        ;;
    esac
    i=$((i + 1))
  done

  if ((seen_form == 0)) && ((seen_positional == 0)); then
    while IFS='' read -r completion; do
      COMPREPLY+=("${completion}")
    done < <(terminator::krisp::__cache_candidates__ "${cur}")
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
  export -f terminator::krisp::__tag_valid__
  export -f terminator::krisp::__date_valid__
  export -f terminator::krisp::__date_next__
  export -f terminator::krisp::__api_get__
  export -f terminator::krisp::__meetings__
  export -f terminator::krisp::__resolve_meeting__
  export -f terminator::krisp::__cache_candidates__
  export -f terminator::krisp::__cache_entries_in_range__
  export -f terminator::krisp::__cache_path__
  export -f terminator::krisp::__cache_write__
  export -f terminator::krisp::__cache_read__
  export -f terminator::krisp::__cache_entry_valid__
  export -f terminator::krisp::__cache_entry_tags__
  export -f terminator::krisp::__cache_set_tags__
  export -f terminator::krisp::__cache_retag__
  export -f terminator::krisp::__cache_untag__
  export -f terminator::krisp::__cache_rename_tag__
  export -f terminator::krisp::__tag_vocabulary__
  export -f terminator::krisp::__tag_apply__
  export -f terminator::krisp::__tag_rename__
  export -f terminator::krisp::__range_fetch__
  export -f terminator::krisp::__format_transcript__
  export -f terminator::krisp::__cache_filename__
  export -f terminator::krisp::__render_markdown__
  export -f terminator::krisp::__human_size__
  export -f terminator::krisp::__migrate_legacy_cache__
  export -f terminator::krisp::__migrate_cache_names__
  export -f terminator::krisp::__json_pull__
  export -f terminator::krisp::__single_pull__
  export -f terminator::krisp::__rows_pull__
  export -f terminator::krisp::__range_pull__
  export -f terminator::krisp::__picker_pull__
  export -f terminator::krisp::__cache_select__
  export -f terminator::krisp::__cache_rm__
  export -f terminator::krisp::__cache_clear__
  export -f terminator::krisp::__color_auto__
  export -f terminator::krisp::__tag_token__
  export -f terminator::krisp::__cache_view_rows__
  export -f terminator::krisp::__cache_view__
  export -f terminator::krisp::__pick_entries__
  export -f terminator::krisp::__pick_meetings__
  export -f terminator::krisp::__pick_tags__
  export -f terminator::krisp::__tag_session__
  export -f terminator::krisp::__usage__
  export -f terminator::krisp::list
  export -f terminator::krisp::get
  export -f terminator::krisp::cache
  export -f terminator::krisp::tag
  export -f terminator::krisp::__completion__
}

# KCOV_EXCL_START
function terminator::krisp::__recall__ {
  unset TERMINATOR_KRISP_API_URL
  unset TERMINATOR_KRISP_CACHE_DIR

  export -fn terminator::krisp::__require_api_key__
  export -fn terminator::krisp::__require_curl__
  export -fn terminator::krisp::__require_jq__
  export -fn terminator::krisp::__tag_valid__
  export -fn terminator::krisp::__date_valid__
  export -fn terminator::krisp::__date_next__
  export -fn terminator::krisp::__api_get__
  export -fn terminator::krisp::__meetings__
  export -fn terminator::krisp::__resolve_meeting__
  export -fn terminator::krisp::__cache_candidates__
  export -fn terminator::krisp::__cache_entries_in_range__
  export -fn terminator::krisp::__cache_path__
  export -fn terminator::krisp::__cache_write__
  export -fn terminator::krisp::__cache_read__
  export -fn terminator::krisp::__cache_entry_valid__
  export -fn terminator::krisp::__cache_entry_tags__
  export -fn terminator::krisp::__cache_set_tags__
  export -fn terminator::krisp::__cache_retag__
  export -fn terminator::krisp::__cache_untag__
  export -fn terminator::krisp::__cache_rename_tag__
  export -fn terminator::krisp::__tag_vocabulary__
  export -fn terminator::krisp::__tag_apply__
  export -fn terminator::krisp::__tag_rename__
  export -fn terminator::krisp::__range_fetch__
  export -fn terminator::krisp::__format_transcript__
  export -fn terminator::krisp::__cache_filename__
  export -fn terminator::krisp::__render_markdown__
  export -fn terminator::krisp::__human_size__
  export -fn terminator::krisp::__migrate_legacy_cache__
  export -fn terminator::krisp::__migrate_cache_names__
  export -fn terminator::krisp::__json_pull__
  export -fn terminator::krisp::__single_pull__
  export -fn terminator::krisp::__rows_pull__
  export -fn terminator::krisp::__range_pull__
  export -fn terminator::krisp::__picker_pull__
  export -fn terminator::krisp::__cache_select__
  export -fn terminator::krisp::__cache_rm__
  export -fn terminator::krisp::__cache_clear__
  export -fn terminator::krisp::__color_auto__
  export -fn terminator::krisp::__tag_token__
  export -fn terminator::krisp::__cache_view_rows__
  export -fn terminator::krisp::__cache_view__
  export -fn terminator::krisp::__pick_entries__
  export -fn terminator::krisp::__pick_meetings__
  export -fn terminator::krisp::__pick_tags__
  export -fn terminator::krisp::__tag_session__
  export -fn terminator::krisp::__usage__
  export -fn terminator::krisp::list
  export -fn terminator::krisp::get
  export -fn terminator::krisp::cache
  export -fn terminator::krisp::tag
  export -fn terminator::krisp::__completion__
}
# KCOV_EXCL_STOP

terminator::__module__::export
