import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeSet;

public class BashVarMap extends BashVar {
  Map<String, String> value;
  protected BashVarMap(String varName, Map<String, String> newValue) {
    super(varName);
    value = newValue;
  }

  @Override
  public String asString() {
    throw new RuntimeException("Can't represent a map as a string");
  }

  @Override
  public boolean hasValue() {
    return !value.isEmpty();
  }

  @Override
  public Long asLong() {
    throw new RuntimeException("Can't represent a map as a long");
  }

  @Override
  public BashVar put(Object newValue) {
    switch(newValue) {
      case Map map -> {
        value = map;
      }
      default -> {
        throw new RuntimeException("Can't put this type into a map: " + newValue.getClass().getName());
      }
    }
    return this;
  }

  @Override
  public BashVar putKey(Object index, String newValue) {
    if (index instanceof String indexString) {
      value.put(indexString, newValue);
    } else {
      throw new RuntimeException("Can only use Strings in putKey of a Map var");
    }
    return this;
  }

  @Override
  public int getSize() {
    return value.size();
  }

  @Override
  public String toString() {
    StringBuilder result = new StringBuilder("(");
    final TreeSet<Map.Entry<String, String>> sortedSet = new TreeSet<>(value.entrySet());
    int i = 0;
    for (Map.Entry<String, String> entry : sortedSet) {
      if (i++ >= 20) {
        result.append(" ...");
        break;
      }
      result.append(" " + entry.getKey() + "=" + entry.getValue());
    }
    result.append(" )");
    return "Map: " + name + "=" + result.toString();
  }

  public boolean containsKey(String key) {
    return value.containsKey(key);
  }

  public String getMapValue(String key, String defaultValue) {
    if (value.containsKey(key)) {
      return value.get(key);
    } else {
      return defaultValue;
    }
  }

  @Override
  public String bashValue() {
    final StringBuilder b = new StringBuilder();
    b.append("( ");

    for (Map.Entry<String, String> entry : value.entrySet()) {
      b.append(shellQuoted(entry.getKey())).append(" ")
       .append(shellQuoted(entry.getValue())).append(" ");
    }

    b.append(")");

    return b.toString();
  }

  public void unsetKey(Object index) {
    if (index instanceof String indexString) {
      value.remove(indexString);
    } else {
      throw new RuntimeException("Can only use Strings in unsetKey of a Map var");
    }
  }

  @Override
  public BashVarMap clone() {
    return new BashVarMap(name, new HashMap<>(value));
  }

  public boolean isEqualToVar(BashVar var) {
    if (var instanceof BashVarMap bvm) {
      return value.equals(bvm.value);
    } else {
      return false;
    }
  }

}
