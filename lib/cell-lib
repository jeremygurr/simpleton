#!/bin/bash
# depends on lib/bash-lib being sourced first to provide needed aliases

[[ -v cell_lib_loaded ]] && return 0
cell_lib_loaded=t

cell_lib_init() {
  # don't let other users read any files written by these scripts
  umask 0077

  empty_member=_ 

  : ${risk_tolerance:=${risk:-0}}
  case "$risk_tolerance" in
    l*)
      risk_tolerance=0
      ;;
    m*)
      risk_tolerance=1
      ;;
    h*)
      risk_tolerance=2
      ;;
    v*)
      risk_tolerance=3
      ;;
    [0-9])
      :
      ;;
    *)
      log_fatal "Unknown risk level: $risk. Should be one of: low medium high very_high (or 0 1 2 3). Defaults to low."
      fail1
      ;;
  esac

  parallel_default=t
  [[ ${debug:-f} == t ]] && parallel_default=f
  parallel_execution=${parallel_execution:-${par:-$parallel_default}}

  command_aliases=()
  command_alias_command=()

  trace_dims=${trace_dims:-${trace_dim:-}}
}

