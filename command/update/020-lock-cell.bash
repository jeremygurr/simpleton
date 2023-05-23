lock_cell() {
current_job_path=
if [[ "$job_path" ]]; then
  current_job_path=$job_path/current
  folder_to_lock=$current_job_path folder_lock || return 1
fi
if [[ "$log_path" ]]; then
  if [[ ! -d $log_path ]]; then
    mkdir -p $log_path || fail
  fi
  if [[ ! "$job_path" ]]; then
    local contents=( $log_path/* )
    if [[ "$contents" != $log_path/'*' ]]; then
      rm $log_path/* 
    fi
  fi
  change_log_file $log_path/update || return 1
fi
if [[ "$status_path" ]]; then
  touch $status_path/last-start || return 1
fi
return 0
}

