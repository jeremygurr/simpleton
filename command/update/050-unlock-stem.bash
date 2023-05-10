unlock_stem() {
if [[ "$stem_job_path" ]]; then
  folder_to_unlock=$current_stem_job_path folder_unlock || fail
fi
if [[ "$stem_log_path" ]]; then
  change_log_file - || fail
fi
}
