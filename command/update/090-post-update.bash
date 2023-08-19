post_update() {
  local result_string

  begin_function_flat

    completion_time=${completion_time:-$EPOCHSECONDS}
    if [[ $update_successful == t ]]; then
      result_string="successful"
    else
      result_string="failed"
    fi

    if [[ $pretend == f ]]; then

      if [[ $update_successful == t ]]; then
        touch -d @$completion_time $status_path/last-good-update-end || fail
        cp -a $status_path/last-update-start \
              $status_path/last-good-update-start || fail
        force=t safe_link $current_job_path $job_path/last-success || fail
        if [[ "${props:-}" ]]; then
          update_prop_hash || fail
        fi
        if [[ $something_changed == t ]]; then
          from_cell=$cell_path \
            propagate_change_to_downstream || fail
        fi
        if [[ "${downstream_ref_path:-}" ]]; then
          log_debug "Linking upstream cell to it's downstream cell cyto up folder"
          force=t safe_link $cell_path $downstream_ref_path || fail
        fi
      else
        touch -d @$completion_time $status_path/last-bad-update-end || fail
        force=t safe_link $current_job_path $job_path/last-failure || fail
        cp -a $status_path/last-update-start \
              $status_path/last-bad-update-start || fail
      fi

      if [[ $cell_is_leaf == t || $show_branches == t ]]; then
        log_info "Update $result_string. ($short_cell)"
      else
        log_debug "Update $result_string. ($short_cell)"
      fi

    else
      log_info "Pretend update $result_string."
    fi

    if [[ "${reply_file:-}" ]]; then
      echo "update_successful=${update_successful:-}" >>$reply_file || fail
    fi

    local lock_fd
    begin_for lock_fd in ${locks[*]}; doo
      cell_unlock || fail
    end_for
    locks=

    cell_unlock $cell_path || fail
    if [[ $cell_usage_lock == f ]]; then
      rm $lock_file_path || fail
    fi

    rm $running_job_path || fail

  end_function
  handle_return
}
