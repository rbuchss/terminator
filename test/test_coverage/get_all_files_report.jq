.files
  | map(. + {
    file: (.file | sub($base_path; "") | sub("^/"; "")),
    percent_covered: (.percent_covered | tonumber),
  })
  | sort_by(.percent_covered)
  | .[]
  | "\(.percent_covered)%\t\(.file)"
