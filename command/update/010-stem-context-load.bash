#!/bin/bash

stem_context_load() {
setup_stem_path_vars $stem || return 1
load_context $stem || return 1
if [[ ! -d $stem/.cyto ]]; then
  init_stem $stem || return 1
fi
}

