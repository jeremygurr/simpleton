lock_stem() {
current_stem_job_path=
if [[ "$stem_job_path" ]]; then
  current_stem_job_path=$stem_job_path/current
  folder_to_lock=$current_stem_job_path folder_lock || fail
  if [[ "$stem_log_path" ]]; then
    if [[ ! -d $stem_log_path ]]; then
      mkdir -p $stem_log_path || fail
    fi
    change_log_file $stem_log_path/update || fail
  fi
fi
}

