check_self() {
if type -t check >/dev/null; then
  check || return 1
  out "$short_stem: $status"
else
  warn "No check operator defined for this stem cell: $short_stem"
fi
return 0
}