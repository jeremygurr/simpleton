check_results() {

begin_function_flat

if [[ $can_update == t ]]; then
  if [[ $update_successful == t && $post_validate == t ]]; then
    log_debug "Post validating"
    local check_successful=f
    can_retry=f
    execute_op check || return 1
    if [[ $check_successful == f ]]; then
      log_debug "Validation failed"
      update_successful=f
    fi
  fi
else
  update_successful=t
fi

end_function
handle_return

}

