#!/bin/bash

block_before() {
if [[ -d "${dna_up_path:-}" && ! "$update_successful" ]]; then
  upstreams=( $(find1 $dna_up_path \
    -not -name '.*' \
    -not -name '*.prep' \
    -not -regex '.*/\([0-9]+-\)?\(before\|after\|choose\)-.*' \
    | sort -g \
    ) )
  previous_upstream_changed=f
else
  upstreams=
fi
}

