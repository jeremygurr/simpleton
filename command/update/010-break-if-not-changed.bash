break_if_not_changed() {
begin_function_flat
  if [[ ! "${needs_update:-}" ]]; then
    needs_update=t
    if [[ "$status_path" ]]; then
      get_needs_update $cell_path || fail
    fi
  fi
  if [[ $needs_update == f ]]; then
    leave_loop=1
  fi
end_function_flat
handle_return
}

