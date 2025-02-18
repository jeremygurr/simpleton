import java.util.List;
import java.util.Map;

public abstract class BashVar implements Comparable<BashVar>, Cloneable {
  public final String name;

  public BashVar(String varName) {
    this.name = varName;
  }

  public static BashVar make(String varName, Object newValue) {
    switch (newValue) {
      case Map map -> {
        return new BashVarMap(varName, map);
      }
      case List list -> {
        return new BashVarList(varName, list);
      }
      case String string -> {
        return new BashVarString(varName, string);
      }
      case Boolean bool -> {
        return new BashVarString(varName, bool ? "t" : "f");
      }
      case Long longVar -> {
        return new BashVarLong(varName, longVar);
      }
      case Integer intVar -> {
        return new BashVarLong(varName, intVar.longValue());
      }
      default -> {
        throw new RuntimeException("Can't make a var out of this type: " + newValue.getClass().getName());
      }
    }
  }

  // this works like BASH where if this var is a list, it will return the first value of that list
  public String asString() {
    throw new RuntimeException("Can't run asString on a this class " + getClass().getName());
  }

  public Long asLong() {
    throw new RuntimeException("Can't run asLong on a this class " + getClass().getName());
  }

  public abstract boolean hasValue();

  public abstract BashVar put(Object newValue);

  public String getEl(int index) {
    throw new RuntimeException("Can't run getEl on a non-array variable");
  }

  public int getSize() {
    throw new RuntimeException("Can't run getSize on a non-array variable");
  }

  public boolean isString() {
    switch (this) {
      case BashVarString _ -> {
        return true;
      }
      default -> {
        return false;
      }
    }
  }

  public BashVar putKey(Object index, String newValue) {
    throw new RuntimeException("putKey can't be run on " + getClass().getName());
  }

  public void unsetKey(Object index) {
    throw new RuntimeException("unsetKey can't be run on " + getClass().getName());
  }

  public String toString() {
    throw new RuntimeException("No toString defined for this class: " + getClass().getName());
  }

  public boolean containsKey(String key) {
    throw new RuntimeException("Can't run containsKey on this class: " + getClass().getName());
  }

  public String getMapValue(String key, String defaultValue) {
    throw new RuntimeException("Can't run getMapValue on this class: " + getClass().getName());
  }

  public String getMapValue(String key) {
    return getMapValue(key, null);
  }

  public boolean stringContains(String containsThis) {
    throw new RuntimeException("Can't run stringContains on this class: " + getClass().getName());
  }

  public boolean isEqualTo(Object value) {
    throw new RuntimeException("Can't run isEqualTo on this class: " + getClass().getName());
  }

  public void append(String toAppend) {
    throw new RuntimeException("Can't run append on this class: " + getClass().getName());
  }

  public boolean valueIsGenerated() {
    return false;
  }

  @Override
  public int compareTo(BashVar o) {
    return name.compareTo(o.name);
  }

  public abstract String bashValue();

  protected String escape(String raw) {
    return raw.replaceAll("\n", "\\n")
        .replaceAll("\t", "\\t")
        ;
  }

  protected String shellQuoted(String raw) {
    String result = raw;
    if (result.matches("\\W")) {
      result = "$'" + escape(raw) + "'";
    }
    return result;
  }

  @Override
  abstract public BashVar clone();

  abstract public boolean isEqualToVar(BashVar var);

  public List<String> asList() {
    throw new RuntimeException("This var can't be represented as a list");
  }

  public boolean asBoolean() {
    throw new RuntimeException("This var can't be represented as a boolean");
  }
}
