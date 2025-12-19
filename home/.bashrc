#!/usr/bin/env bash

if [[ "${bashrc_already_run}" ]]; then
  return 0
fi

echo "Executing ~/.bashrc"
bashrc_already_run=t
source /etc/profile.d/shell-start*
