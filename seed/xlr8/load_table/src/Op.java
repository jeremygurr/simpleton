public class Op extends CellOp {

  int main(BashVars vars) {
    vars.return_value=0;
    begin_function(vars);
      System.out.println("** name=" + vars.get("name"));
    end_function(vars);
    return vars.return_value;
  }

  private boolean y() {
    return false;
  }

  private boolean x() {
    return false;
  }

}


