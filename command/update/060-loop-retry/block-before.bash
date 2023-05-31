block_before() {

ref_group=none
delay=$retry_delay

handle_step_loop() {

local can_update=f
if type -t update >/dev/null || [[ -e $op_path/update ]]; then
  can_update=t
fi

local action=local_update
for ((retry=0; retry < retry_max; retry++)); do

  if [[ $retry -gt 0 ]]; then
    info "Waiting $delay seconds before trying again" 
    sleep $delay
    let 'delay *= retry_scale' || true
  fi

  info "Executing local update of $short_cell"
  debug "Attempt $((retry+1)) of $retry_max" 

  execute_command_step_folder || return 1

  local result_string
  if [[ $update_successful == t ]]; then
    result_string="successful"
  else
    result_string="failed"
  fi

  if [[ $pretend == f ]]; then
    if [[ "$status_path" ]]; then
      if [[ $update_successful == t ]]; then
        touch $status_path/last-good-update || return 1
      else
        touch $status_path/last-bad-update || return 1
      fi
    fi
    info "Update $result_string."
  else
    info "Pretend update $result_string."
  fi

  [[ $can_retry == f || $update_successful == t ]] && break

done

return 0

}

}

