lock_stem() {
current_stem_job_path=
if [[ "$stem_job_path" ]]; then
  current_stem_job_path=$stem_job_path/current
  folder_to_lock=$current_stem_job_path folder_lock || fail
fi
}

