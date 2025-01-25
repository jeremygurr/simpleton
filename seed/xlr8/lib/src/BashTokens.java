import java.util.ArrayList;
import java.util.List;

import static java.lang.Math.min;

public class BashTokens {
  private final String input;
  private final List<BashToken> tokens;

  public BashTokens(String input, List<BashToken> tokens) {
    this.input = input;
    this.tokens = tokens;
  }

  public static BashTokens make(String input) {
    final ArrayList<BashToken> tokens = new ArrayList<>();
    int pos = 0;
    while(pos < input.length()) {

      BashToken token = null;

      if (token == null) token = DqStringToken.make(input, pos);
      if (token == null) token = SqStringToken.make(input, pos);
      if (token == null) token = WhiteSpaceToken.make(input, pos);
      if (token == null) token = EqualsToken.make(input, pos);
      if (token == null) token = VarToken.make(input, pos);

      if (token == null) {
        throw new RuntimeException("Could not tokenize string at pos " + pos + ": " + input.substring(pos, min(pos+20, input.length())));
      }

      pos++;

    }
    return new BashTokens(input, tokens);
  }
}
