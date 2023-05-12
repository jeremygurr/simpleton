before_block() {

delay=$retry_delay
retries=$(seq $retry_max)

handle_step_loop() {
for ((retry=0; retry < retry_max; retry++)); do
  execute_command_step_plain_folder || return 1
  [[ $can_retry == f || $update_successful == t ]] && break
done
return 0
}

}
