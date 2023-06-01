get_value() {
if [[ -e $dna_path/op/get ]]; then
  execute_op get || return 1
else
  if [[ "$out_path" ]]; then
    if [[ -e $out_path/value ]]; then
      if [[ $multi_cell == t ]]; then
        out "$short_cell: $(<$out_path/value)"
      else
        out "$(<$out_path/value)"
      fi
    else
      warn "$short_cell: No cached value."
    fi
  else
    debug "$short_cell: No out_path defined."
  fi
fi
return 0
}