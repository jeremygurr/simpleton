update_self() {
  begin_function
    update_successful=f
    [[ $trace_update == t ]] && set -x
    update || fail
    set +x
  end_function
  handle_return
}