unlock_batch() {
if [[ "$batch_job_path" ]]; then
  folder_to_unlock=$current_batch_job_path folder_unlock || fail
fi
}

