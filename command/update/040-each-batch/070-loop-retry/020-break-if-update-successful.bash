break_if_update_successful() {
  if [[ $update_successful == t ]]; then
    do_after=break
  fi
}