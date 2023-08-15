create_downstream_links() {
  begin_function_flat

  if [[ "${downstream_ref_path:-}" ]]; then
    local cell_path down_cell_path down_cell_name

    get_cell_path ${downstream_ref_path%/*} || fail
    down_cell_path=$cell_path

    get_cell_name $down_cell_path || fail
    down_cell_name=${cell_name%% *}

    local down_link=$down_path/$down_cell_name
    if [[ ! -e $down_link ]]; then
      if [[ ! -d $down_path ]]; then
        mkdir $down_path || fail
      fi
      safe_link $down_cell_path $down_link || fail
    else
      local link_target=$(readlink $down_link) || fail
      if [[ $link_target != $down_cell_path ]]; then
        log_fatal "Link conflict: A link already exists but doesn't point to the same place."
        log_fatal "  $link_target is expected to point to $down_cell_path"
      fi
    fi
  fi

  end_function
  handle_return
}