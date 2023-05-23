update_self() {
begin_function
  update_successful=f 
  can_retry=f

  if [[ "$out_path" ]]; then
    local original_out=$out_path
    local out_path=$out_path.new
    if [[ -d $out_path ]]; then
      rm -rf $out_path || fail
    fi
    mkdir $out_path || fail
  fi

  execute_op update || fail

  if [[ "$out_path" ]]; then
    out_path=$original_out
    if [[ $update_successful == t ]]; then
      if [[ -e $out_path.old ]]; then
        rm -rf $out_path.old || fail
      fi
      mv $out_path $out_path.old || fail
      mv $out_path.new $out_path || fail
    fi
  fi

end_function
handle_return
}