#!/bin/bash

block_after() {
  touch $status_path/deps-up-to-date || return 1
  touch $status_path/up-to-date || return 1
  return 0
}

