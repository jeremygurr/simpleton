import java.io.*;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Main {

  private static String hexToAscii(String hexString) {
    StringBuilder sb = new StringBuilder();

    for (int i = 0; i < hexString.length() - 1; i += 2) {
      String hex = hexString.substring(i, i + 2);
      int decimal = Integer.parseInt(hex, 16);
      sb.append((char) decimal);
    }

    return sb.toString();
  }

  private static String escapeCodeToString(String escapeCode) {
    final char first = escapeCode.charAt(0);
    String result = "";
    switch (first) {
      case 'n':
        result = "\n";
        break;
      case 't':
        result = "\t";
        break;
      case 'x':
        result = hexToAscii(escapeCode.substring(1));
        break;
      default:
        throw new RuntimeException("Unknown escape code: " + escapeCode);
    }
    return result;
  }

  private static String unescape(String escapedContent) {
    final StringBuilder b = new StringBuilder();
    String remaining = escapedContent;
    while (!remaining.isEmpty()) {
      final Pattern pattern = Pattern.compile("^([^\\\\]*)\\\\(n|t|x..)(.*)$");
      final Matcher matcher = pattern.matcher(remaining);
      if (matcher.matches()) {
        b.append(matcher.group(1));
        b.append(escapeCodeToString(matcher.group(2)));
        remaining = matcher.group(3);
      } else {
        b.append(remaining);
        break;
      }
    }

    return b.toString();
  }

  private static void importVars(BashVars vars, Reader reader) throws IOException {
    final BufferedReader in = new BufferedReader(reader);
    final Pattern quotedPattern = Pattern.compile("^(\\w+)=\\$'(.*)'$");
    final Pattern simplePattern = Pattern.compile("^(\\w+)=(\\w*)$");
    while (true) {

      final String line = in.readLine();
      if (line == null) {
        break;
      }

      Matcher matcher = quotedPattern.matcher(line);
      if (matcher.matches()) {
        final String varName = matcher.group(1);
        final String content = matcher.group(2);
        vars.put(varName, unescape(content));
      } else {
        matcher = simplePattern.matcher(line);
        if (matcher.matches()) {
          final String varName = matcher.group(1);
          final String content = matcher.group(2);
          vars.put(varName, unescape(content));
        } else {
          throw new RuntimeException("Invalid assignment statement in input: " + line);
        }
      }

    }

  }

  private static void exportVars(BashVars vars, Writer writer) throws IOException {
    final List<BashVar> changedVars = vars.getChangedVars();

    final BufferedWriter w = new BufferedWriter(writer);
    for (BashVar var : changedVars) {
      w.write(var.name + "=" + var.bashValue() + "\n");
    }
    w.flush();
  }

  public static void main(String[] args) throws Exception {
    final Op op = new Op();
    final BashVars vars = BashVars.make();
    InputStream in = System.in;
    if (args.length > 0) {
      in = new FileInputStream(args[0]);
    }
    importVars(vars, new InputStreamReader(in));
    vars.saveOriginals();
    vars.putIfUnset("debug_id_current", 0);
    op.main(vars);
    exportVars(vars, new OutputStreamWriter(System.out));
  }

}
