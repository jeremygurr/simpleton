import java.util.ArrayList;
import java.util.List;

public class BashVarList extends BashVar {
  private List<String> value;

  public static BashVarList make() {
    return new BashVarList(new ArrayList<>());
  }

  protected BashVarList(List<String> newValue) {
    value = newValue;
  }

  @Override
  public BashVar putKey(Object index, Object newValue) {
    if (index instanceof Long indexLong) {
      value.set(Math.toIntExact(indexLong), newValue.toString());
    } else {
      throw new RuntimeException("Can only use Longs in putKey of a List var");
    }
    return this;
  }

  @Override
  public String asString() {
    if (value.size() > 0) {
      return value.get(0);
    }
    return "";
  }

  @Override
  public boolean hasValue() {
    return !value.isEmpty();
  }

  @Override
  public Long asLong() {
    throw new RuntimeException("Can't represent a list as a long");
  }

  @Override
  public BashVar put(Object newValue) {
    switch(newValue) {
      case List list -> {
        value = list;
      }
      default -> {
        throw new RuntimeException("Can't put this type into a list: " + newValue.getClass().getName());
      }
    }
    return this;
  }

  @Override
  public String getEl(int index) {
    return value.get(index);
  }

  @Override
  public int getSize() {
    return value.size();
  }

  @Override
  public void unsetKey(Object index) {
    if (index instanceof Long indexLong) {
      value.remove(Math.toIntExact(indexLong));
    } else {
      throw new RuntimeException("Can only use Longs in unsetKey of a List var");
    }
  }

  @Override
  public String toString() {
    StringBuilder result = new StringBuilder("(");
    for (int i = 0; i < value.size(); i++) {
      if (i >= 20) {
        result.append(" ...");
        break;
      }
      result.append(" " + value.get(i));
    }
    result.append(" )");
    return result.toString();
  }
}
