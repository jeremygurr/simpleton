update_upstream() {
if [[ -f $upstream.prep ]]; then
  source $upstream.prep || return 1
fi
get_node_needs_update $upstream || return 1
if [[ $needs_update == t ]]; then
  execute_command_step "$(realpath $upstream)" || return 1
fi
return 0
}
