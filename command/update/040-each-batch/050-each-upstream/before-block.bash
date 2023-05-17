#!/bin/bash

before_block() {
# skip before- and choose-
upstreams=( $(find1 $dna_path/up -not -name '.*' -not -regex '.*/\([0-9]+-\)?\(before\|choose\)-.*')  )
}

