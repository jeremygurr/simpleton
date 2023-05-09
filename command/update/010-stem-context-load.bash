#!/bin/bash

stem_context_load() {
load_context $stem || return 1
if [[ ! -d $stem/.cyto ]]; then
  make_cyto $stem || return 1
fi
setup_stem_path_vars $stem || return 1
}

