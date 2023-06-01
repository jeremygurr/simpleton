get_member() {
local sane_value member_path
vars=member; begin_function
  get_sane_value "$member" || fail
  member_path=$cell_path/.dim/$sane_value
  if [[ ! -d $member_path ]]; then
    warn "This member hasn't been created yet: $member. Use 'cell update' to create missing cells."
  else
    execute_command $member_path get || fail
  fi
end_function
handle_return
}

