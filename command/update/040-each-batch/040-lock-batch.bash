lock_batch() {
current_batch_job_path=
if [[ "$batch_job_path" ]]; then
  current_batch_job_path=$batch_job_path/current
  folder_to_lock=$current_batch_job_path folder_lock || fail
fi
}

