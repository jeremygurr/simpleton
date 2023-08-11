pre_update() {
  begin_function_flat

    update_successful=
    something_changed=f

    from=$current_job_path \
      to=$running_job_path \
      timeout=5000 \
      link_lock || fail

    touch $status_path/last-update-start || fail
    # this needs to be at the beginning of the update so other processes
    #   could potentially invalidate it, requiring another update
    touch $status_path/up-to-date || fail

    if [[ $reuse_existing_out == t && -f $status_path/last-good-update-end ]]; then
      # Don't allow cells to reuse old data when it is mid-modification and this update fails
      rm $status_path/last-good-update-end || fail
    fi

  end_function
  handle_return
}
