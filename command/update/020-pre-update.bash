pre_update() {
update_successful=f
something_changed=f
if [[ "$current_job_path" ]]; then
  folder_to_lock=$current_job_path folder_lock || return 1
fi
if [[ "$log_path" ]]; then
  if [[ ! -d $log_path ]]; then
    mkdir -p $log_path || return 1
  fi
  if [[ ! "$job_path" ]]; then
    rm -rf $log_path || return 1
    mkdir $log_path || return 1
  fi
  change_log_file $log_path/update || return 1
fi
if [[ "$status_path" ]]; then
  touch $status_path/last-start || return 1
fi
return 0
}
