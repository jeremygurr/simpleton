import java.util.List;
import java.util.Map;

public abstract class BashVar {
  public static BashVar make(Object newValue) {
    switch (newValue) {
      case Map map -> {
        return new BashVarMap(map);
      }
      case List list -> {
        return new BashVarList(list);
      }
      case String string -> {
        return new BashVarString(string);
      }
      case Long longVar -> {
        return new BashVarLong(longVar);
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
      case BashVarString _ -> { return true; }
      default -> { return false; }
    }
  }

  public BashVar putKey(Object index, Object newValue) {
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
}

