public class BashIgnore {
  public static int skipWhitespace(String input, int pos) {
    for (; pos < input.length(); pos++) {
      final char c = input.charAt(pos);
      if (!Character.isWhitespace(c)) {
        break;
      }
    }
    return pos;
  }

  /**
   * Skips whitespace and bash comments
   */
  public static int skipIgnorable(String input, int pos) {
    for (; pos < input.length(); pos++) {
      final char c = input.charAt(pos);
      if (c == '#') {
        int nextNewline = input.indexOf('\n', pos);
        if (nextNewline == -1) nextNewline = input.length();
        pos = nextNewline;
      } else if (!Character.isWhitespace(c)) {
        break;
      }
    }
    return pos;
  }

}
