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
  select(any(.file; IN ($files[])))
;

def file_report_to_text:
  @text "| \(.file) | \(.total_lines) | \(.covered_lines) | \(.percent_covered)% | \(.threshold)% | \(.status_symbol) |"
;

.files
  | get_file_status($base_path; $threshold; $pass_symbol; $fail_symbol)[]
  | filter_files($files)
  | file_report_to_text
