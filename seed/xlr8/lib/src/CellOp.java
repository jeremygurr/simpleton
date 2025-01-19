public abstract class CellOp {

  void begin_function(BashVars vars) {
    debug_id_inc(vars);
  }

  private void debug_id_inc(BashVars vars) {
    vars.inc("debug_id_current");
  }

  void end_function(BashVars vars) {
  }

}

