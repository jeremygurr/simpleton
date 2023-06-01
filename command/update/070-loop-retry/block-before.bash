block_before() {

ref_group=none
delay=$retry_delay

handle_step_loop() {

can_update=f
find_op_or_function update || return 1
if [[ "$found_op_function" || "$found_op" ]]; then
  can_update=t
fi

local action=local_update
for ((retry=0; retry < retry_max; retry++)); do

  if [[ $retry -gt 0 ]]; then
    info "Waiting $delay seconds before trying again" 
    sleep $delay
    let 'delay *= retry_scale' || true
  fi

  info "Executing local update of $cell_path"
  debug "Attempt $((retry+1)) of $retry_max" 

  execute_command_step_folder || return 1

  [[ $can_retry == f || $update_successful == t ]] && break

done

return 0

}

}

