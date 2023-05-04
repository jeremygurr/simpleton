#!/bin/bash

stem_context_load() {
load_context $stem || return 1
if [[ ! -d $stem/.cyto ]]; then
  init_stem $stem || return 1
fi
}

