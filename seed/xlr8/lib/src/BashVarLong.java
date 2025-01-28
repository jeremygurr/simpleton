public class BashVarLong extends BashVar {
  // never null
  private Long value;

  public BashVarLong(String varName, Long newValue) {
    super(varName);
    value = newValue;
  }

  @Override
  public String asString() {
    return value.toString();
  }

  @Override
  public boolean hasValue() {
    return true;
  }

  @Override
  public Long asLong() {
    return value;
  }

  @Override
  public BashVar put(Object newValue) {
    switch(newValue) {
      case Long long_value -> {
        value = long_value;
      }
      case String string_value -> {
        value = Long.parseLong(string_value);
      }
      default -> {
        throw new RuntimeException("Can't put this type into a long: " + newValue.getClass().getName());
      }
    }
    return this;
  }

  public String toString() {
    return value.toString();
  }

  public boolean isEqualTo(Object value) {
    return this.value.equals(value);
  }

  @Override
  public String bashValue() {
    return value.toString();
  }

}
