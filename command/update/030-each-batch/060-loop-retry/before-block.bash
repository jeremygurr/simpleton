delay=$retry_delay
retries=$(seq $retry_max)

handle_step_loop() {
for ((retry=0; retry < retry_max; retry++)); do
  local do_after=
  execute_command_step_plain_folder || return 1
  [[ "$do_after" == break ]] && break
done
return 0
}

