update_self() {
begin_function
  update_successful=f 
  can_retry=f

  if [[ "$batch_out_path" ]]; then
    local original_batch_out=$batch_out_path
    batch_out_path=$batch_out_path.new
    if [[ -d $batch_out_path ]]; then
      rm -rf $batch_out_path || fail
    fi
  fi

  execute_op update || fail

  if [[ "$batch_out_path" ]]; then
    batch_out_path=$original_batch_out
    if [[ $update_successful == t ]]; then
      if [[ -e $batch_out_path.old ]]; then
        rm -rf $batch_out_path.old || fail
      fi
      mv $batch_out_path $batch_out_path.old || fail
      mv $batch_out_path.new $batch_out_path || fail
    fi
  fi

end_function
handle_return
}