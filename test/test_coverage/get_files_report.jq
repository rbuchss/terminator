def get_file_status(base_path; threshold; pass_symbol; fail_symbol):
    map(. + {
      file: (.file | sub(base_path; "") | sub("^/"; "")),
      threshold: (threshold | tonumber),
      percent_covered: (.percent_covered | tonumber),
    })
    | map(. + {
      status_symbol: (if .percent_covered >= .threshold then pass_symbol else fail_symbol end)
    })
;

def filter_files(files):
  .[] | select(any(.file; IN ($files[])))
;

def file_report_to_text:
  @text "| \(.file) | \(.total_lines) | \(.covered_lines) | \(.percent_covered)% | \(.threshold)% | \(.status_symbol) |"
;

# Note jq currently does not support sorting multiple fields by differing directions.
# Often we need to chain something like this:
#   | sort_by(.file) # field we want asc
#   | reverse
#   | sort_by(.percent_covered) # field we want desc
#   | reverse
# See: https://github.com/jqlang/jq/issues/2491
# For now adding this patch to enable this
# reverse-sort by f while retaining the ordering within groups defined by f
def reverse_by(f):
  group_by(f) | reverse | [.[][]];

# sort using multiple criteria.
# `criteria` and `$directions` should be arrays of the same length.
# If $directions[$i] is 1, then sort_by(criteria[$i]) is used, otherwise reverse_by(criteria[$i]) is used.
# The final ordering will ensure that criteria[$i] takes precedence over criteria[$i+1] for all relevant $i.
def multisort_by( criteria; $directions ):
  if $directions == [] then .
  elif $directions[-1] == 1 then sort_by(criteria[-1]) | multisort_by( criteria[:-1]; $directions[:-1] )
  else reverse_by(criteria[-1]) | multisort_by( criteria[:-1]; $directions[:-1] )
  end;

.files
  | get_file_status($base_path; $threshold; $pass_symbol; $fail_symbol)
  | multisort_by([.percent_covered, .file]; [-1, 1])
  | filter_files($files)
  | file_report_to_text
