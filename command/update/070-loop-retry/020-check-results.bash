check_results() {

if [[ $can_update == t ]]; then
  if [[ $update_successful == t ]]; then
    if [[ $post_validate == t ]]; then
      local status=good
      ignore_missing=t execute_op check || return 1
      if [[ $status == bad ]]; then
        update_successful=f
        can_retry=f
      fi
    fi
  fi
else
  update_successful=t
fi

}

