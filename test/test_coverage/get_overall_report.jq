def get_overall_status(threshold; pass_symbol; fail_symbol):
  . + {
    threshold: (threshold | tonumber),
    percent_covered: (.percent_covered | tonumber),
  }
  | . + {
    status_symbol: (if .percent_covered >= .threshold then pass_symbol else fail_symbol end)
  }
;

def overall_report_to_text:
  @text "| \(.total_lines) | \(.covered_lines) | \(.percent_covered)% | \(.threshold)% | \(.status_symbol) |"
;

.
  | get_overall_status($threshold; $pass_symbol; $fail_symbol)
  | overall_report_to_text
