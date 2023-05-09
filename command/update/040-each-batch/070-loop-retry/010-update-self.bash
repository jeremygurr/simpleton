update_self() {
  begin_function
    update_successful=f
    update || fail
  end_function
  handle_return
}