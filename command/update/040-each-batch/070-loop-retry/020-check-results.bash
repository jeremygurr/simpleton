check_results() {
if [[ $update_successful == t && "$post_validate" == t ]]; then
  ignore_missing=t execute_op check || fail
  if [[ $status == bad ]]; then
    update_successful=f
    can_retry=f
  fi
fi
}