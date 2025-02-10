import java.io.*;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public abstract class CellOp {

  final private String DIM_DEBUG_COLOR;
  final private String DIM_RED="\033[0;31m";
  final private String RED="\033[1;31m";
  final private String DIM_GREEN="\033[0;32m";
  final private String GREEN="\033[1;32m";
  final private String DIM_YELLOW="\033[0;33m";
  final private String YELLOW="\033[1;33m";
  final private String DIM_BLUE="\033[0;34m";
  final private String BLUE="\033[1;34m";
  final private String DIM_PURPLE="\033[0;35m";
  final private String PURPLE="\033[1;35m";
  final private String DIM_CYAN="\033[0;36m";
  final private String CYAN="\033[1;36m";
  final private String DIM_WHITE="\033[0;37m";
  final private String WHITE="\033[1;37m";
  final private String DIM_BLACK="\033[0;38m";
  final private String BLACK="\033[1;38m";
  final private String RESET="\033[0m";
  final private String CLEAR_LINE="\033[2K\r";
  final private String CLEAR="\033[2J";
  final private String CLEAR_SCREEN="\033[2J\r\033[H";
  final private String CURSOR_UP="\033[1A";
  final private String REVERSE="\033[7m";
  final private String NL="\n";

  protected CellOp() {
    DIM_DEBUG_COLOR = DIM_CYAN;
  }

  void begin_function(BashVars vars) {
    final String current_function = vars.getEl("FUNCNAME", 1);
    vars.addContext()
        .local("return_value", 0)
        .local("break_out", "f")
        .local("function_level", 1)
        .local("repair_attempted", "f")
        .local("current_function", current_function)
        .local("timebox_stack", List.of(vars.getEl("FUNCNAME", 1)))
        .local("trace_time_start")
        .local("trace_time_start_debug_id")
        .local("trace_time_stop")
        .local("time_dur")
        .local("stack_pos", vars.getSize("FUNCNAME") - 1)
        .local("struct_type", "start of " + current_function)
    ;
    trace_time_open(vars);
    debug_id_inc(vars);
    vars.clear("log_vars").clear("log_show_vars");
    vars.putKey("stack_debug_id", vars.getLong("stack_pos"), vars.get("fork_debug_id"));
    if (vars.isTrue("debug_step_to_mid_function")) {
      vars.put("debug_id", "t");
      vars.put("debug_immediate", "t");
      debug_start(vars);
    }
  }

  private void debug_start(BashVars vars) {
    throw new RuntimeException("Not implemented yet");
  }

  private void trace_time_open(BashVars vars) {
    if (vars.isTrue("trace_time")) {
      if (!vars.hasValue("trace_time_fd")) {
        String traceTimeLog = "/tmp/trace_time.log";
        vars.putIfUnset("trace_time_log", traceTimeLog);
        final File file = new File(traceTimeLog);
        if (file.exists()) {
          file.delete();
        }
        vars.put("trace_time_start", currentTimeInMicroseconds());
        vars.put("trace_time_start_debug_id", vars.get("fork_debug_id"));
      }
    }
  }

  private BufferedWriter trace_time_fd = null;
  private void out_to_time_log(BashVars vars, String message) {
    if (trace_time_fd == null) {
      String trace_time_log = vars.get("trace_time_log");
      try {
        trace_time_fd = new BufferedWriter(new FileWriter(trace_time_log));
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    }
    try {
      trace_time_fd.write(message);
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  private void trace_time_close(BashVars vars, String currentFunction) {
    if (vars.isTrue("trace_time") && vars.hasValue("trace_time_fd")) {
      final long trace_time_stop = currentTimeInMicroseconds();
      vars.put("trace_time_stop", trace_time_stop);
      final long trace_time_start = vars.getLong("trace_time_start");
      final long time_dur = trace_time_stop - trace_time_start;
      final String timebox = vars.get("timebox");
      final String trace_time_start_debug_id = vars.get("trace_time_start_debug_id");
      final String fork_debug_id = vars.get("fork_debug_id");
      out_to_time_log(vars, time_dur + " " + timebox + " " + trace_time_start_debug_id + " " + fork_debug_id);
    }
  }

  private long currentTimeInMicroseconds() {
    long new_time = System.nanoTime() / 1000;
    return new_time;
  }

  void end_function(BashVars vars) {
    final String current_function = vars.get("current_function");
    if (vars.getLong("function_level") > 0) {
      vars.put("struct_type", "end of " + current_function);
      debug_id_inc(vars);
      final Long stack_pos = vars.getLong("stack_pos");
      vars.unset("stack_debug_id", stack_pos)
          .unset("stack_detail", stack_pos)
          .unset("stack_high_level", stack_pos)
      ;
    }
    final long function_level = vars.getLong("function_level");
    switch (Math.toIntExact(function_level)) {
      case 2:
        trace_time_close(vars, current_function);
        load_log_vars_and_write_to_log(vars);
        vars.dec("log_depth_current");
      case 1:
        trace_time_close(vars, current_function);
    }
    vars.removeContext();
    vars.put("debug_return_vars", vars.get("log_return_vars", ""));
  }

  private void load_log_vars_and_write_to_log(BashVars vars) {
    throw new RuntimeException("Not implemented");
  }

  private String show_time_update(BashVars vars) {
    String prefix="";
    if (vars.get("show_time", "f").equals("t")) {
      final long new_time = currentTimeInMicroseconds();
      if (vars.hasValue("show_time_prev")) {
        final long old_time = vars.getLong("show_time_prev");
        final long diff = new_time - old_time;
        final long seconds = diff / 1000000;
        final long micros = diff - seconds * 1000000;
        prefix += seconds + "." + micros + " ";
      }
      vars.put("show_time_prev", new_time);
    }

    return prefix;
  }

  private void err(String message) {
    System.err.println(message);
  }

  // Shows a representation of the value of this var which is suitable for debugging or logging
  private String get_var_value(BashVars vars, String varName) {
    final BashVar var = vars.getVar(varName);
    return var.toString();
  }

  private void exit(BashVars vars, int code) {
    System.exit(code);
  }

  private void pause_qd(BashVars vars, String message) {
    String extra="";
    if (vars.hasValue("fork_debug_id")) {
      extra=" at " + vars.get("fork_debug_id");
    }

    if (message == null) message = "";

    String pauseResponse;

    System.err.print(NL + WHITE + "** PAUSED" + extra + " ** " + message + " Press q to quit, D to debug here or any other key to continue." + RESET);
    System.err.print(NL);

    int i = 0;
    try {
      i = System.in.read();
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
    if (i < 0) {
      exit(vars, 1);
    }

    char c = (char)i;

    switch(c) {
      case 'D' -> {
        debug_start(vars);
      }
      case 'q' -> {
        System.err.println("Quitting.");
        exit(vars, 1);
      }
    }
  }

  private void eval(BashVars vars, String bashStatement) {
    throw new RuntimeException("eval not implemented yet");
  }

  private String stripLeading(String var, String toStrip) {
    return var.replaceFirst("^" + toStrip, "");
  }

  private String stripTrailing(String var, String toStrip) {
    return var.replaceFirst(toStrip + "$", "");
  }

  private void show_trace_vars(BashVars vars) {
    final String prefix = show_time_update(vars);
    if (vars.isTrue("trace_structure")) {
      if (vars.hasValue("struct_type")) {
        err(" " + prefix + DIM_DEBUG_COLOR + "debug_id="
            + vars.get("fork_debug_id") + RESET + " "
            + vars.get("struct_type", ""));

      }
    }
    if (vars.hasValue("trace_fun")) {
      for (String fun : vars.split("trace_fun")) {
        if (vars.endsWith("struct_type", " " + fun)) {
          err(" " + prefix + DIM_DEBUG_COLOR + "debug_id="
              + vars.get("fork_debug_id") + " " + vars.get("struct_type", "") + RESET);
        }
      }
    }

    if (vars.hasValue("trace_var")) {
      for (String var : vars.split("trace_var")) {
        final String value = get_var_value(vars, var);
        if (vars.containsKey("trace_var_sub", var)) {
          if (!vars.getMapValue("trace_var_sub", var).equals(value)) {
            String show_val = value;
            if (vars.hasValue("secret_vars")
                && vars.stringContains("secret_vars", var)) {
              show_val="****";
            }
            err(" " + prefix + DIM_DEBUG_COLOR + "debug_id="
                + vars.get("fork_debug_id") + " " + YELLOW
                + var + "=" + show_val + RESET);
            if (vars.hasValue("pause_at_vars") && vars.stringContains("pause_at_vars", var)) {
              pause_qd(vars, "Var changed: $var.");
            }
          }
          vars.unset("trace_var_sub", var);
          vars.putKey("trace_var_old", var, value);
        } else if (!vars.getMapValue("trace_var_old", var, "").equals(value)
            || vars.get("trace_var_always", "f").equals("t")
        ) {
          String show_val = value;
          if (vars.hasValue("secret_vars")
              && vars.stringContains("secret_vars", var)) {
            show_val="****";
          }
          if (!vars.isEqual("fork_debug_id", "1")
              || !vars.isSet(var)) {
            err(" " + prefix + DIM_DEBUG_COLOR + "debug_id="
                + vars.get("fork_debug_id") + " " + YELLOW
                + var + "=" + show_val + RESET);
            if (vars.hasValue("pause_at_vars") && vars.stringContains("pause_at_vars", var)) {
              pause_qd(vars, "Var changed: $var.");
            }
          }
          vars.unset("trace_var_sub", var);
          vars.putKey("trace_var_old", var, value);
        }
      }
    }

    if (vars.hasValue("trace_condition")) {
      vars.unsetFlags("u");
      vars.addContext();
      vars.local("result");
      eval(vars, "if $trace_condition; then result=t; else result=f; fi");
      final String result = vars.get("result");
      vars.setFlags("u");
      if (!vars.isEqual("trace_var_old", result)) {
        err(" " + prefix + DIM_DEBUG_COLOR + "debug_id=" + vars.get("fork_debug_id")
            + " " + vars.get("trace_condition") + "=" + result);
        vars.put("trace_var_old", result);
      }
      vars.removeContext();
    }

    if (vars.hasValue("trace_expression")) {
      vars.unsetFlags("u");
      vars.addContext();
      vars.local("result");
      eval(vars, "if $trace_condition; then result=t; else result=f; fi");
      final String result = vars.get("result");
      vars.setFlags("u");
      if (!vars.isEqual("trace_var_old", result)) {
        err(" " + prefix + DIM_DEBUG_COLOR + "debug_id=" + vars.get("fork_debug_id")
            + " expression=" + result);
        vars.put("trace_var_old", result);
      }
      vars.removeContext();
    }

    if (vars.hasValue("log_show_vars")) {
      StringBuilder show_vars= new StringBuilder();
      for (String var : vars.split("log_show_vars")) {
        String real_var = stripLeading(vars.get(var), "\\^");
        real_var = stripLeading(real_var, ".*=");
        final String value = get_var_value(vars, real_var);
        show_vars.append(real_var).append("=").append(value).append(" ");
      }
      vars.putKey("stack_detail", vars.get("stack_pos"),
          stripTrailing(show_vars.toString(), " *"));
    }

  }

  private boolean reached_debug_id(String fork_debug_id, String debug_id) {
    final String[] r1 = fork_debug_id.split(".");
    final String[] r2 = debug_id.split(".");
    for (int i = 0; i < r1.length; i++) {
      if (i >= r2.length) {
        return true;
      }
      final int p1 = Integer.parseInt(r1[i]);
      final int p2 = Integer.parseInt(r2[i]);
      if (p1 < p2) {
        return false;
      } else if (p1 > p2) {
        return true;
      }
    }
    return true;
  }

  private String prompt_ynq(BashVars vars, String message) {
    if (message == null) message = "";
    String pauseResponse;
    char c;
    while (true) {
      System.err.print(GREEN + message + RESET + " (y/n/q) ");

      int i = 0;
      try {
        i = System.in.read();
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
      if (i < 0) {
        exit(vars, 1);
      }

      c = (char)i;
      switch (c) {
        case 'y' -> {
          System.err.println("Yes");
        }
        case 'n' -> {
          System.err.println("No");
        }
        case 'q' -> {
          System.err.println("Quit");
        }
        default -> {
          System.err.println("Pick one of: (y)es (n)o (q)uit");
          continue;
        }
      }
      break;
    }

    return String.valueOf(c);
  }

  private String debug_get_new_bisect(BashVars vars, String new_bisect) {
    String new_command = vars.get("original_cmd");
    Pattern pattern = Pattern.compile("^(.*) (debug_)?bisect=[^\\ ]+(\\ .*)?$");
    Matcher matcher = pattern.matcher(new_command);
    if (matcher.matches()) {
      String pre = matcher.group(1);
      String post = matcher.group(3);
      new_command = pre + post;
    }

    pattern = Pattern.compile("(([0-9]+\\.)*[0-9]+)\\.\\.(([0-9]+\\.)*[0-9]+)");
    matcher = pattern.matcher(new_bisect);
    String debug_bisect_min = matcher.group(1);
    String debug_bisect_max = matcher.group(3);

    // TODO need to handle forked debug_ids (with .)
    // DOESN'T work with forking for now

    if (debug_bisect_min.equals(debug_bisect_max)) {
      new_command += " debug=" + debug_bisect_max + " - 1";  // This won't work, need to figure out how to subtract from forked id
      err(YELLOW + "Bisect complete, debugging just before issue occurs: " + RESET + new_command);
    } else {
      new_command += " bisect=$new_bisect";
      err(CYAN + "Starting next bisect: " + RESET + new_command);
    }

    return new_command;
  }

  private void debug_id_inc(BashVars vars) {
    vars.inc("debug_id_current");

    if (vars.hasValue("fork_id_current")) {
      vars.put("fork_debug_id", vars.get("fork_id_current") + ".");
    }
    vars.append("fork_debug_id", vars.get("debug_id_current"));

    show_trace_vars(vars);

    if (vars.hasValue("struct_type")
    ) {
      if (vars.hasValue("pause_at_functions")
          && vars.stringContains("pause_at_functions", vars.getEl("FUNCNAME", 1))) {
        pause_qd(vars, "Reached " + vars.get("struct_type") + ".");
      }
    }

    if (vars.hasValue("debug_id") && !vars.isEqual("debug_id", "t")
        && reached_debug_id(vars.get("fork_debug_id"), vars.get("debug_id"))
    ) {
      if (vars.hasValue("debug_bisect_min")) {
        String new_bisect = "";
        if (vars.hasValue("bisect_test")) {
          eval(vars, vars.get("bisect_test"));
        }
        final String response = prompt_ynq(vars, "Debug bisect: Did the problem happen?");
        switch(response) {
          case "y":
            new_bisect=vars.get("debug_bisect_min") + ".." + vars.get("debug_id");
            break;
          case "n":
            new_bisect=vars.getLong("debug_id") + 1 + ".." + vars.get("debug_bisect_max");
            break;
          case "q":
            exit(vars, 1);
        }
        final String new_command = debug_get_new_bisect(vars, new_bisect);
        vars.put("debug_restart_command", new_command);
        vars.put("debug_exit", "t");
        vars.clear("debugging");
        exit(vars, 100);
      } else {
        vars.put("debug_id", "t");
        vars.put("debug_immediate", "t");
        // this is different than bash code, because debugger is more limited
        debug_start(vars);
      }
    } else if (
        vars.hasValue("debug_quick_function")
        && vars.isEqual("debug_quick_function", vars.getEl("FUNCNAME", 1))
        ) {
      vars.put("debug_function_old", vars.get("debug_quick_function"));
      vars.clear("debug_quick_function");
      vars.put("debug_immediate", "t");
      // this is different than bash code, because debugger is more limited
      debug_start(vars);
    }

    if (vars.hasValue("debug_quick_stop_less_than_depth")
        && vars.sizeOf("FUNCNAME")
        <= vars.getLong("debug_quick_stop_less_than_depth")
    ) {
      vars.clear("debug_quick_stop_less_than_depth");
      vars.put("debug_immediate", "t");
      // this is different than bash code, because debugger is more limited
      debug_start(vars);
    }

  }

}
