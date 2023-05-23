unlock_cell() {
if [[ "$job_path" ]]; then
  folder_to_unlock=$current_job_path folder_unlock || fail
fi
if [[ "$log_path" ]]; then
  change_log_file - || fail
fi
}
