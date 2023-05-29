#!/bin/bash

block_after() {
if [[ "$status_path" ]]; then
  touch $status_path/deps-up-to-date || return 1
fi
return 0
}

