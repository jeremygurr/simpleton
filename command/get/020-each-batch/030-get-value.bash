get_value() {
if [[ -e $dna_path/op/get ]]; then
  execute_op get || return 1
else
  if [[ -e $batch_out_path/value ]]; then
    out "$short_stem: $(<$batch_out_path/value)"
  else
    warn "$short_stem: No cached value."
  fi
fi
return 0
}