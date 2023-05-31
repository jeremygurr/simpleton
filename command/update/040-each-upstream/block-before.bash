#!/bin/bash

block_before() {
if [[ "$up_path" ]]; then
  upstreams=( $(find1 $up_path \
    -not -name '.*' \
    -not -name '*.prep' \
    -not -regex '.*/\([0-9]+-\)?\(before\|choose\)-.*' \
    ) )
else
  upstreams=
fi
}

