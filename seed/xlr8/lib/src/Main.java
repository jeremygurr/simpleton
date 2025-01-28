import java.io.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static java.lang.Math.min;

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
    final Pattern pattern = Pattern.compile("(\\w+)=\\$'(.*)'");
    while (true) {

      final String line = in.readLine();
      if (line == null) {
        break;
      }

      final Matcher matcher = pattern.matcher(line);
      if (!matcher.matches()) {
        throw new RuntimeException("Invalid assignment statement in input: " + line);
      }

      final String varName = matcher.group(1);
      final String content = matcher.group(2);
      vars.put(varName, unescape(content));

    }

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
