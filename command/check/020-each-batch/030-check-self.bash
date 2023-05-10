check_self() {
execute_op check || return 1
out "$short_stem: $status"
return 0
}