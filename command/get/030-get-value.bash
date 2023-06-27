get_value() {
if [[ -e $op_path/get ]]; then
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
      if [[ $cell_is_leaf == t || $show_branches == t ]]; then
        warn "$short_cell: No cached value."
      fi
    fi
  else
    if [[ $cell_is_leaf == t || $show_branches == t ]]; then
      debug "$short_cell: No out_path defined."
    fi
  fi
fi
return 0
}