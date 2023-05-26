#!/bin/bash

make_subs() {
if [[ "$sub_path" ]]; then
  create_sub_cells $cell_path
  local sub_full sub
  for sub_full in $(find1 $sub_path -not -name ".*" -not -name "$wild_sub_path" | sort -g); do
    sub=${sub_full##*/}
    create_sub_cell $cell_path/$sub || return 1
  done
fi
return 0
}

