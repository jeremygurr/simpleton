pre_update() {
update_successful=
something_changed=f
if [[ "$current_job_path" ]]; then
  folder_to_lock=$current_job_path folder_lock || return 1
fi
if [[ "$status_path" ]]; then
  touch $status_path/last-update-start || return 1
  # this needs to be at the beginning of the update so other processes
  #   could potentially invalidate it, requiring another update
  touch $status_path/up-to-date || return 1
fi
if [[ $reuse_existing_out == t && -f $status_path/last-good-update-end ]]; then
  # Don't allow cells to reuse old data when it is mid-modification and this update fails
  rm $status_path/last-good-update-end || return 1
fi
return 0
}
