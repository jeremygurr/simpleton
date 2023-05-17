#!/bin/bash

before_block() {
if [[ "$stem_up_path" ]]; then
  upstreams=( $(find1 $stem_up_path -not -name '.*' -not -regex '.*/\([0-9]+-\)?\(before\|choose\)-.*')  )
else
  upstreams=
fi
}

