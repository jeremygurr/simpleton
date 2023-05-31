update_self() {
begin_function
  update_successful=f 
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
      fi
      if [[ ! -d $out_path ]]; then
        mkdir $out_path || fail
      fi
    fi

    tee_output_to_log || fail
    execute_op update || fail
    untee_output || fail

    if [[ "$out_path" && $reuse_existing_out == f ]]; then
      out_path=$original_out
      if [[ $update_successful == t ]]; then
        if [[ -e $out_path.old ]]; then
          rm -rf $out_path.old || fail
        fi
        if [[ -d $out_path ]]; then
          mv $out_path $out_path.old || fail
        fi
        mv $out_path.new $out_path || fail
      fi
    fi

  fi

end_function
handle_return
}