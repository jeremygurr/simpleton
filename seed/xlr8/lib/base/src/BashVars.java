import java.util.*;

public class BashVars {

  // These maps can contain null for the value of a key, meaning that the variable is declared but not set
  private final List<Map<String, BashVar>> contexts = new ArrayList<>();
  private final Map<String, BashVar> originalValues = new HashMap<>();
  public int return_value = 0;
  public boolean flag_u = false;

  public static BashVars make() {
    final BashVars vars = new BashVars();
    vars.addContext();
    return vars;
  }

  public List<BashVar> getChangedVars() {
    final List<BashVar> result = new ArrayList<>();

    for (BashVar var : contexts.get(0).values()) {
      if (!var.valueIsGenerated() && !var.isEqualToVar(originalValues.get(var.name))) {
        result.add(var);
      }
    }

    Collections.sort(result);
    return result;
  }

  // will not fail if var doesn't exist, but returns null instead
  public BashVar getVarOrNull(String varName) {
    BashVar var = null;
    for(int i = contexts.size() - 1; i >= 0; i--) {
      final Map<String, BashVar> varMap = contexts.get(i);
      if(varMap.containsKey(varName)) {
        var = varMap.get(varName);
      }
    }
    if(varName.equals("FUNCNAME")) {
      var = BashVarFuncname.make();
    }
    return var;
  }

  // will fail if var doesn't exist
  public BashVar getVar(String varName) {
    BashVar var = getVarOrNull(varName);
    if (var != null) {
      return var;
    } else {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }
  }

  // Will fail if the var doesn't exist
  public BashVars inc(String varName) {
    final BashVar var = getVar(varName);
    Long x = var.asLong();
    var.put(x + 1);
    return this;
  }

  public BashVars dec(String varName) {
    final BashVar var = getVar(varName);
    Long x = var.asLong();
    var.put(x - 1);
    return this;
  }

  // Will never fail
  public boolean isSet(String varName) {
    for(int i = contexts.size() - 1; i >= 0; i--) {
      final Map<String, BashVar> varMap = contexts.get(i);
      if(varMap.containsKey(varName)) {
        return true;
      }
    }
    return false;
  }

  // Will never fail, unless defaultValue is given as null
  public String get(String varName, String defaultValue) {
    BashVar var = getVarOrNull(varName);
    if (var != null) {
      return var.asString();
    } else if (defaultValue != null) {
      return defaultValue;
    } else {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }
  }

  // Will fail if var doesn't exist
  public String get(String varName) {
    return get(varName, null);
  }

  public List<String> getList(String varName) {
    BashVar var = getVarOrNull(varName);
    if (var != null) {
      return var.asList();
    } else {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }
  }

  // Will NOT fail if var doesn't exist.
  public boolean hasValue(String varName) {
    final BashVar var = getVarOrNull(varName);
    if (var != null) {
      return var.hasValue();
    }
    return false;
  }

  // Will never fail, unless defaultValue is given as null
  // or var can't be represented as a long
  public long getLong(String varName, Long defaultValue) {
    BashVar var = getVarOrNull(varName);
    if (var != null) {
      return var.asLong();
    } else if (defaultValue != null) {
      return defaultValue;
    } else {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }
  }

  // Will fail if var doesn't exist or can't be converted to long
  public long getLong(String varName) {
    return getLong(varName, null);
  }

  // will create a new var if it doesn't already exist
  public BashVars put(String varName, Object newValue) {
    final BashVar var = getVarOrNull(varName);
    if (var != null) {
      var.put(newValue);
    } else {
      final Map<String, BashVar> context = contexts.getFirst();
      context.put(varName, BashVar.make(varName, newValue));
    }
    return this;
  }

  // Will fail if var doesn't exist, is not an array, or index doesn't exist
  public String getEl(String arrayName, int index) {
    final BashVar var = getVar(arrayName);
    return var.getEl(index);
  }

  // Never fails
  public BashVars addContext() {
    contexts.add(new HashMap<>());
    return this;
  }

  // Will fail if no more contexts exist
  public BashVars removeContext() {
    if (!contexts.isEmpty()) {
      contexts.removeLast();
    } else {
      throw new RuntimeException("No more contexts exist to be removed");
    }
    return this;
  }

  // Will do nothing if var already exists in the top context of the stack
  public BashVars local(String varName, Object defaultValue) {
    final Map<String, BashVar> last = contexts.getLast();
    if (!last.containsKey(varName)) {
      if (defaultValue != null) {
        last.put(varName, BashVar.make(varName, defaultValue));
      } else {
        last.put(varName, null);
      }
    }
    return this;
  }

  public BashVars local(String varName) {
    return local(varName, null);
  }

  public int getSize(String arrayName) {
    final BashVar var = getVar(arrayName);
    return var.getSize();
  }

  /**
   *
   * @param varName
   * @return true if varName exists and is true. Returns false if it doesn't exist or is set to false.
   */
  public boolean isTrue(String varName) {
    final BashVar var = getVarOrNull(varName);
    if (var == null) {
      return false;
    } else if (var.isString()) {
      return var.asString().equals("t");
    } else {
      throw new RuntimeException("Var " + varName + " is not a String");
    }
  }

  public BashVars putIfUnset(String varName, Object newValue) {
    BashVar var = getVarOrNull(varName);
    if (var == null) {
      put(varName, newValue);
    } else if (!var.hasValue()) {
      var.put(newValue);
    }
    return this;
  }

  public BashVars clear(String varName) {
    return put(varName, "");
  }

  // Will create a new array var if it doesn't already exist
  public BashVars putKey(String varName, Object index, String newValue) {
    BashVar var = getVarOrNull(varName);
    if (var == null) {
      var = BashVarList.make(varName);
      final Map<String, BashVar> context = contexts.getLast();
      context.put(varName, var);
    }
    var.putKey(index, newValue);
    return this;
  }

  // unset a specific element of a list
  // does nothing if the var doesn't exist
  public BashVars unsetKey(String varName, Object index) {
    BashVar var = getVarOrNull(varName);
    if (var != null) {
      var.unsetKey(index);
    }
    return this;
  }

  // unset a specific element of a list
  // does nothing if the var doesn't exist
  public BashVars unset(String varName) {
    for(int i = contexts.size() - 1; i >= 0; i--) {
      final Map<String, BashVar> varMap = contexts.get(i);
      if(varMap.containsKey(varName)) {
        varMap.remove(varName);
        break;
      }
    }
    return this;
  }

  public BashVars unset(String... vars) {
    for (String var : vars) {
      unset(var);
    }
    return this;
  }

  public String[] split(String varName) {
    final BashVar var = getVar(varName);
    if (var.isString()) {
      final String string = var.asString().trim();
      return string.split(" +");
    } else {
      throw new RuntimeException("Var is not a string: " + varName);
    }
  }

  public boolean endsWith(String varName, String endsWithString) {
    final String value = get(varName);
    return value.endsWith(endsWithString);
  }

  public boolean containsKey(String varName, String key) {
    final BashVar var = getVarOrNull(varName);

    if (var == null) {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }

    return var.containsKey(key);
  }

  public String getMapValue(String varName, String key, String defaultValue) {
    final BashVar var = getVarOrNull(varName);

    if (var == null) {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }

    return var.getMapValue(key, defaultValue);
  }

  public String getMapValue(String varName, String key) {
    return getMapValue(varName, key, null);
  }

  public boolean stringContains(String varName, String containsThis) {
    final BashVar var = getVarOrNull(varName);

    if (var == null) {
      throw new RuntimeException("Var doesn't exist: " + varName);
    }

    return var.stringContains(containsThis);
  }

  // will fail if var doesn't exist
  public boolean isEqual(String varName, String value) {
    final BashVar var = getVar(varName);
    return var.isEqualTo(value);
  }

  public BashVars unsetFlags(String flags) {
    for(int i = 0; i < flags.length(); i++) {
      char flag = flags.charAt(i);
      switch(flag) {
        case 'u' -> {
          flag_u = false;
        }
        default -> {
          throw new RuntimeException("Unknown flag " + flag);
        }
      }
    }
    return this;
  }

  public BashVars setFlags(String flags) {
    for(int i = 0; i < flags.length(); i++) {
      char flag = flags.charAt(i);
      switch(flag) {
        case 'u' -> {
          flag_u = true;
        }
        default -> {
          throw new RuntimeException("Unknown flag " + flag);
        }
      }
    }
    return this;
  }

  public BashVars append(String varName, String toAppend) {
    final BashVar var = getVarOrNull(varName);
    String newValue;
    if (var == null) {
      put(varName, toAppend);
    } else {
      var.append(toAppend);
    }
    return this;
  }

  public int sizeOf(String varName) {
    final BashVar var = getVar(varName);
    return var.getSize();
  }

  public BashVars saveOriginals() {
    final Map<String, BashVar> map = contexts.get(0);
    for (BashVar var : map.values()) {
      originalValues.put(var.name, var.clone());
    }
    return this;
  }

}

