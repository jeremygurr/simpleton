update_member() {
local sane_value member_path
vars=member; begin_function
  get_sane_value "$member" || fail
  member_path=$cell_path/.dim/$sane_value
  if [[ ! -d $member_path ]]; then
    if [[ ! -d $cell_path/.dim ]]; then
      mkdir $cell_path/.dim || fail
    fi
    create_sub_cell $member_path || fail
  fi
  execute_command $member_path update || fail
end_function
handle_return
}
