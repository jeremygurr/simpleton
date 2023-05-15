lock_batch() {
current_batch_job_path=
if [[ "$batch_job_path" ]]; then
  current_batch_job_path=$batch_job_path/current
  folder_to_lock=$current_batch_job_path folder_lock || return 1
fi
if [[ "$batch_log_path" ]]; then
  if [[ ! -d $batch_log_path ]]; then
    mkdir -p $batch_log_path || return 1
  fi
  if [[ ! "$batch_job_path" ]]; then
    local contents=( $batch_log_path/* )
    if [[ "$contents" != $batch_log_path/'*' ]]; then
      rm $batch_log_path/* 
    fi
  fi
  change_log_file $batch_log_path/update || return 1
fi
if [[ "$batch_status_path" ]]; then
  touch $batch_status_path/last-started-update || return 1
fi
return 0
}

