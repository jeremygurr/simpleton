block_before() {

ref_group=none
delay=$retry_delay

handle_step_loop() {

local can_update=f
if type -t update >/dev/null || [[ -e $op_path/update ]]; then
  can_update=t
fi

for ((retry=0; retry < retry_max; retry++)); do
  write_to_log debug update_retry "Attempt $((retry+1)) of $retry_max" || return 1
  execute_command_step_folder || return 1
  [[ $can_retry == f || $update_successful == t ]] && break
  write_to_log debug update_retry "Waiting $delay seconds" || return 1
  sleep $delay
  let 'delay *= retry_scale' || true
done

return 0

}

}
