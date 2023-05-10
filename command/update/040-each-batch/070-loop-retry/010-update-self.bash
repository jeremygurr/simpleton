update_self() {
begin_function
  update_successful=f 
  can_retry=f
  execute_op update || fail
end_function
handle_return
}