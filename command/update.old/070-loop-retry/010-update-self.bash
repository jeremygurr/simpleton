update_self() {
  local log_vars='short_cell'
  begin_function
    update_successful=
    can_retry=f

    if [[ $can_update == t ]]; then

      local reuse_existing_out=${reuse_existing_out:-f}

      if [[ "$out_path" ]]; then
        if [[ $reuse_existing_out == f ]]; then
          local original_out=$out_path
          local out_path=$out_path.new
          if [[ -d $out_path ]]; then
            rm -rf $out_path || fail
          fi
        else
          # allow update code to set this, since we can't compare when changes are made in place
          something_changed=
        fi
        if [[ ! -d $out_path ]]; then
          mkdir $out_path || fail
        fi
      fi

      tee_output_to_log || fail
      execute_op update || fail
      completion_time=$EPOCHSECONDS
      untee_output || fail

      update_successful=${update_successful:-f}

      if [[ "$out_path" ]]; then
        if [[ $reuse_existing_out == f ]]; then
          out_path=$original_out
          if [[ $update_successful == t ]]; then
            if files_are_same -r $out_path $out_path.new &>/dev/null; then
              rm -rf $out_path.new || fail
            else
              if [[ -e $out_path.old ]]; then
                rm -rf $out_path.old || fail
              fi
              if [[ -d $out_path ]]; then
                mv $out_path $out_path.old || fail
              fi
              mv $out_path.new $out_path || fail
              something_changed=t
            fi
          fi
        else # $reuse_existing_out == t
          # if update code didn't set this, we must assume the worst
          if [[ ! "$something_changed" ]]; then
            something_changed=t
          fi
        fi
      fi

    fi

  end_function
  untee_output  # in case update failed and block was exited early
  handle_return
}
