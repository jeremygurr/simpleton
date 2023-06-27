update_member() {
local sane_value member_path
local log_vars=member 
begin_function
  get_sane_value "$member" || fail
  member_path=$cell_path/.dim/$sane_value
  if [[ ! -d $member_path ]]; then
    if [[ ! -d $cell_path/.dim ]]; then
      mkdir $cell_path/.dim || fail
    fi
    create_sub_cell $member_path || fail
  fi
  get_needs_update $member_path || return 1
  if [[ $needs_update == t ]]; then
    fork execute_command $member_path update || fail
    if [[ $update_successful == f ]]; then
      error "Failed to update member cell $member"
    else 
      update_successful=
    fi
  fi
end_function
handle_return
}

