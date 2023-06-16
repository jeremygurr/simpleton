update_member() {
local sane_value member_path
vars=member; begin_function
  get_sane_value "$member" || fail
  member_path=$cell_path/.dim/$sane_value
  if [[ ! -d $member_path ]]; then
    if [[ ! -d $cell_path/.dim ]]; then
      mkdir $cell_path/.dim || fail
    fi
    create_sub_cell "$seed" $member_path || fail
  fi
  get_node_needs_update $member_path || return 1
  if [[ $needs_update == t ]]; then
    fork execute_command $member_path update || fail
  fi
end_function
handle_return
}

