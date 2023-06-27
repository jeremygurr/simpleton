block_before() {

ref_group=none
delay=$retry_delay

handle_step_loop() {

can_update=f
find_op_or_function update || return 1
if [[ "$found_op_function" || "$found_op" ]]; then
  can_update=t
fi

if [[ "$update_successful" ]]; then
  can_update=f
fi

local action=local_update
if [[ $can_update == t ]]; then
  for ((retry=0; retry < retry_max; retry++)); do

    if [[ $retry -gt 0 ]]; then
      info "Waiting $delay seconds before trying again" 
      sleep $delay
      let 'delay *= retry_scale' || true
    fi

    local attempt_string=
    if (( retry_max > 1 )); then
      attempt_string=", attempt $((retry+1)) of $retry_max"
    fi
      
    debug "Executing local update of $short_cell$attempt_string" 

    execute_command_step_folder || return 1

    [[ $can_retry == f || $update_successful == t ]] && break

  done
fi

update_successful=${update_successful:-t}

return 0

}

}

