import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

/**
 * Emulates FUNCNAME array in BASH
 */
public class BashVarFuncname extends BashVar {
  private List<String> externalStack = new ArrayList<>();

  public BashVarFuncname() {
    super("FUNCNAME");
  }

  public static BashVarFuncname make() {
    return new BashVarFuncname();
  }

  @Override
  public boolean hasValue() {
    return true;
  }

  private List<String> getFullStack() {
    final List<String> fullStack = new ArrayList<>(externalStack);
    StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
    // Convert to an array of strings (if needed)
    String[] javaStack = Arrays.stream(stackTrace)
        .map(ste -> ste.getClassName() + "." + ste.getMethodName())
        .toArray(String[]::new);
    fullStack.addAll(List.of(javaStack));
    return fullStack;
  }

  @Override
  public String getEl(int index) {
    final List<String> fullStack = getFullStack();
    if (index >= fullStack.size() || index < 0) {
      throw new RuntimeException("Invalid index for var: " + index + " (max is " + (fullStack.size() - 1) + ")");
    }
    return fullStack.get(index);
  }

  @Override
  public int getSize() {
    final List<String> fullStack = getFullStack();
    return fullStack.size();
  }

  @Override
  public BashVar put(Object newValue) {
    if (newValue instanceof List newList) {
      externalStack = newList;
    } else {
      throw new RuntimeException("The value for the put method must be a List<String>");
    }
    return this;
  }

  @Override
  public boolean valueIsGenerated() {
    return true;
  }

  @Override
  public String bashValue() {
    throw new RuntimeException("Attempted to get bashValue on " + getClass().getName());
  }

  @Override
  public BashVarFuncname clone() {
    return this;
  }

  @Override
  public boolean equals(Object o) {
    if (o == null || getClass() != o.getClass()) return false;
    return true;
  }

  @Override
  public int hashCode() {
    return 0;
  }

  @Override
  public boolean isEqualToVar(BashVar var) {
    return var instanceof BashVarFuncname;
  }
}
