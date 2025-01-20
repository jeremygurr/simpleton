public abstract class CellOp {

  void begin_function(BashVars vars) {
    debug_id_inc(vars);
  }

  private void debug_id_inc(BashVars vars) {
    vars.inc("debug_id_current");
    vars.put("fork_debug_id", vars.getString("debug_id_current"));
    String fork_id_current=vars.getString("fork_id_current");
    if (vars.isNotEmpty("fork_id_current")) {
      fork_debug_id = fork_id_current + "." + fork_debug_id;
    }

            show_trace_vars

    if [[ "${struct_type:-}" && "${pause_at_functions:-}" \
     && " $pause_at_functions " == *" ${FUNCNAME[1]} "* ]]; then
    local pause_response=
            pause_qd "Reached ${struct_type:-}."
    fi

    if [[ "${debug_id:-}" && $debug_id != t ]] && reached_debug_id $debug_id; then
    if [[ "${debug_debug:-}" == t ]]; then
    log_debug_debug "debug_id matched: $debug_id" >&$fd_original_err
    fi
    #debug_ignore_remove ${FUNCNAME[*]:1:4}
    if [[ "${debug_bisect_min:-}" ]]; then
    local response new_bisect
    if [[ "${bisect_test:-}" ]]; then
    eval "$bisect_test"
    fi
    prompt_ynq "Debug bisect: Did the problem happen?" response
    case $response in
    y)
    new_bisect=${debug_bisect_min}..${debug_id}
    ;;
    n)
    new_bisect=$(( debug_id + 1 ))..${debug_bisect_max}
    ;;
    q)
    exit 1
    ;;
    esac
            debug_get_new_bisect
    debug_restart_command=$new_command debug_exit=t debugging=
            exit 100
    else
    debug_id=t
    debug_immediate=t
    debug_start n
    fi
    elif [[ "${debug_quick_function:-}" && $debug_quick_function == ${FUNCNAME[1]} ]]; then
    if [[ "${debug_debug:-}" == t ]]; then
    log_debug_debug "debug_quick_function matched: $debug_quick_function" >&$fd_original_err
      #show_array FUNCNAME
    fi
    #debug_ignore_remove ${FUNCNAME[*]:1:4}
    debug_function_old=$debug_quick_function
    debug_quick_function=
            debug_immediate=t
    debug_start n
    fi

    if [[ "${debug_quick_stop_less_than_depth:-}" ]] && \
    (( ${#FUNCNAME[*]} <= $debug_quick_stop_less_than_depth )); then
            debug_quick_stop_less_than_depth=
            debug_immediate=t
    debug_start n
    fi


  }

  void end_function(BashVars vars) {
  }

}

