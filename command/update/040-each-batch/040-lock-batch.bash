lock_batch() {
begin_function_flat
  current_batch_job_path=
  if [[ "$batch_job_path" ]]; then
    current_batch_job_path=$batch_job_path/current
    folder_to_lock=$current_batch_job_path folder_lock || fail
  fi
  if [[ "$batch_log_path" ]]; then
    if [[ ! -d $batch_log_path ]]; then
      mkdir -p $batch_log_path || fail
    fi
    change_log_file $batch_log_path/update || fail
  fi
  if [[ "$batch_status_path" ]]; then
    touch $batch_status_path/last-started-update || fail
  fi
end_function_flat
handle_return
}

