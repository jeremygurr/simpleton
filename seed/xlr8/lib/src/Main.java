import java.io.*;

import static java.lang.Math.min;

public class Main {

  private static void importVars(BashVars vars, Reader reader) throws IOException {
    final StringWriter writer = new StringWriter();
    reader.transferTo(writer);
    final String input = writer.toString();
    final BashTokens tokens = BashTokens.make(input);
    BashStatements statements = BashStatements.make(tokens);
  }

  private static void exportVars(BashVars vars, Writer writer) {
  }

  public static void main(String[] args) throws Exception {
    final Op op = new Op();
    final BashVars vars = BashVars.make();
    importVars(vars, new InputStreamReader(System.in));
    op.main(vars);
    exportVars(vars, new OutputStreamWriter(System.out));
  }

}
