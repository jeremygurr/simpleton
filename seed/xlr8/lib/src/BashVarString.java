public class BashVarString extends BashVar {
  private String value;

  public BashVarString(String varName, String newValue) {
    super(varName);
    value = newValue;
  }

  @Override
  public String asString() {
    return value;
  }

  @Override
  public boolean hasValue() {
    return !value.isEmpty();
  }

  @Override
  public Long asLong() {
    return Long.parseLong(value);
  }

  @Override
  public BashVar put(Object newValue) {
    switch (newValue) {
      case Long long_value -> {
        value = long_value.toString();
      }
      case String string_value -> {
        value = string_value;
      }
      default -> {
        throw new RuntimeException("Can't put this type into a long: " + newValue.getClass().getName());
      }
    }
    return this;
  }

  @Override
  public String toString() {
    return value;
  }

  public boolean stringContains(String containsThis) {
    return (" " + value + " ").contains(" " + containsThis + " ");
  }

  public boolean isEqualTo(Object value) {
    return this.value.equals(value);
  }

  public void append(String toAppend) {
    value += toAppend;
  }

  @Override
  public String bashValue() {
    return value;
  }

}