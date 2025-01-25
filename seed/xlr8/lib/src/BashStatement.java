public class BashStatement {

  private BashStatement() {
  }

  public static BashStatement make() {
    return new BashStatement();
  }

  /**
   * @return May return null if a valid statement can't be found
   */
  public int load(String input, int pos) {
    //int originalPos = pos;
    pos = BashIgnore.skipIgnorable(input, pos);
    final BashVarAssignment varAssignment = BashVarAssignment.make();
    pos = varAssignment.load(input, pos);
    if (!varAssignment.isEmpty()) {

    }
    return pos;
  }

}
