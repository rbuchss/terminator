def get_overall_status(threshold; pass_symbol; fail_symbol):
  . + {
    threshold: (threshold | tonumber),
    percent_covered: (.percent_covered | tonumber),
  }
  | . + {
    status_symbol: (if .percent_covered >= .threshold then pass_symbol else fail_symbol end)
  }
;

.
  | get_overall_status($threshold; $pass_symbol; $fail_symbol)
  | .status_symbol
