import java.sql.Array;
import java.util.ArrayList;
import java.util.List;

public class Op extends CellOp {

  private void convert_coords_to_dims(BashVars vars, Coordinates c, DimType dimType) {
    final String coord_type=vars.get("coord_type");

    for (int field_index = 0; field_index < c.coordinate_fields_count; field_index++) {
      int data_offset = c.coordinate_fields_count * c.row_index + field_index;
      final String value = c.coordinate_data.get(data_offset);
      final String field = c.coordinate_fields.get(field_index);
      final String fields = c.coordinate_fields_plural.get(field_index);
      vars.unset("s_" + field)
          .unset("s_" + fields)
          .unset("d_" + field)
          .unset("d_" + fields)
      ;
      switch(dimType) {
        case sdims -> {
          vars.put("s_" + fields, value);
        }
        case ddims -> {
          vars.put("d_" + fields, value);
        }
        case sdim -> {
          vars.put("s_" + field, value);
        }
        case ddim -> {
          vars.put("d_" + field, value);
        }
      }
    }
  }

  private List<String> expand_dim(BashVars vars, String dimVarType, String dimVar, String value) {
    begin_function(vars);
    final ArrayList<String> result = new ArrayList<>();

    final String memberVar = dimVarType + "_" + dimVar + "_members";
    if (vars.hasValue(memberVar)) {
      final List<String> members = vars.getList(memberVar);
      if (members.contains(value)) {
        result.add(value);
      }
    }

    final String aliasVar = dimVarType + "_" + dimVar + "_aliases";
    if (result.isEmpty() && vars.hasValue(aliasVar)) {
      final List<String> aliases = vars.getList(aliasVar);
      for (String alias : aliases) {
        String aliasKey = alias.substring(0, alias.indexOf(' '));
        if (aliasKey.equals(value)) {
          result.addAll(List.of(alias.split(" ")).subList(1, 0));
          break;
        }
      }
    }

    if (result.isEmpty() && !vars.hasValue(memberVar)) {
      result.add(value);
    }

    end_function(vars);
    return result;
  }

  private List<String> expand_dim_members(BashVars vars, String dimVarType, String dimVar, List<String> members) {
    begin_function(vars);
    final List<String> new_values = new ArrayList<>();
    for (String value : members) {
      List<String> values = expand_dim(vars, dimVarType, dimVar, value);
      if (!values.isEmpty()) {
        new_values.addAll(values);
      }
    }
    end_function(vars);
    return new_values;
  }

  private void expand_dims(BashVars vars, List<String> dimsToExpand) {
    begin_function(vars);
    for (String dimVar : dimsToExpand) {
      final String dimsVar = get_plural(dimVar);
      final String ddim = "d_" + dimVar;
      final String ddims = "d_" + dimsVar;
      final String sdim = "s_" + dimVar;
      final String sdims = "s_" + dimsVar;
      final String dimVarType = vars.get(dimVar + "_dim_type");
      if (!vars.hasValue(ddim) && !vars.hasValue(ddims) &&
          (vars.hasValue(sdim) || vars.hasValue(sdims))) {
        log_debug("Expanding dim " + dimVar);
        List<String> members;
        boolean single;

        if (vars.hasValue(sdims)) {
          members = vars.getList(sdims);
          single = false;
        } else {
          members = List.of(vars.get(sdim));
          single = true;
        }

        final List<String> new_values = expand_dim_members(vars, dimVarType, dimVar, members);
        if (single == true && new_values.size() > 1) {
          log_fatal("Too many values for " + dimVar + ": " + get_var_value(new_values));
          throw new RuntimeException();
        }

        vars.put(ddims, new_values);
        vars.unset(ddim, sdim, sdims);
      } else if (!vars.hasValue(ddims)) {
        if (vars.hasValue(ddim)) {
          vars.put(ddims, List.of(vars.get(ddim)));
          vars.unset(ddim, sdim, sdims);
        } else {
          vars.unset(ddim, ddims, sdim, sdims);
        }
      }
    }

    end_function(vars);
  }

  private void attempt_derive(BashVars vars, Coordinates c, String dim_type, String dim, String fromDim, boolean findOnlyOne) {
    begin_function(vars);
    final BashVar derived_from = vars.getVarOrNull(dim_type + "_" + dim + "_derived_from");
    final BashVar can_derive = vars.getVar("can_derive");
    final BashVar values = vars.getVar("values");
    boolean derivedFromIncomplete = false;
    final ArrayList<String> resolvedDependencyRows = new ArrayList<>();

    if (derived_from != null) {
      boolean oneRowComplete = false;
      for (String derivedFromRow : derived_from.asList()) {
        if (fromDim != null && stringContains(derivedFromRow, fromDim)) {
          boolean completeRow = true;
          for (String derivedFromDim : derivedFromRow.split(" ")) {
            final String derivedFromDimValue = vars.get("d_" + derivedFromDim, "");
            if (!derivedFromDimValue.isEmpty()) {
              completeRow = false;
              break;
            }
          }
          if (completeRow) {
            oneRowComplete = true;
            resolvedDependencyRows.add(derivedFromRow);
          }
        }
      }
      if (!oneRowComplete) {
        derivedFromIncomplete = true;
      }
    }

    if (!derivedFromIncomplete) {
      
    }

    end_function(vars);
  }

  private boolean calc_coords_validate_member(BashVars vars, Coordinates c, String dim, String member) {
    begin_function(vars);
    boolean isValid = true;
    log_debug("Validating " + dim + " == " + member);
    final String dim_type = vars.get(dim + "_dim_type");
    final boolean is_optional = vars.getBoolean(dim_type + "_" + dim + "_is_optional", false);
    if (!is_optional || !member.equals("")) {
      vars.put("values", List.of());
      vars.put("can_derive", false);
      attempt_derive(vars, c, dim_type, dim, null, false);
      if (vars.getBoolean("can_derive")) {
        if (!vars.hasValue("values")) {
          isValid = false;
        } else if (!vars.containsKey("values", member)) {
          isValid = false;
        }
      } else { // can't derive
        for (String rd : c.resolved_dims) {
          if (rd.equals(dim)) {
            continue;
          }
          attempt_derive(vars, c, dim_type, rd, dim, true);
          if (vars.getBoolean("can_derive")) {
            if (!vars.hasValue("values")) {
              isValid = false;
            } else {
              final String rd_member = vars.get("d_" + rd, "");
              if (!rd_member.isEmpty() && !vars.containsKey("values", rd_member)) {
                isValid = false;
              }
            }
            break;
          }
        }
      }
    }

    end_function(vars);
    return isValid;
  }

  private void calc_coordinates_next_known_dim(BashVars vars, Coordinates c_old) {
    begin_function(vars);
    final Coordinates c = Coordinates.make(c_old);

    if (!c.known_dims.isEmpty()) {
      final String dim = c.known_dims.removeFirst();
      log_debug("Checking known dim " + dim);
      int coord_index = c.coordinate_dim_index.get(dim);
      final String dims = c.coordinate_fields_plural.get(coord_index);
      final String member_var = "d_" + dim;
      final String members_var = "d_" + dims;
      final List<String> members = vars.getList(members_var, vars.getList(member_var, List.of()));

      if (!members.isEmpty()) {
        c.resolved_dims.add(dim);
        vars.addContext();
        vars.unset(members_var);
        for(String m : members) {
          log_debug("Processing " + dim + "=" + m);
          boolean isValid = calc_coords_validate_member(vars, c, dim, m);
          if (isValid) {
            calc_coordinates_next_known_dim(vars, c);
          } else {
            log_debug("Dim member doesn't fit row constraints: " + dim + " = " + m + ", skipping row");
          }
        }
        vars.unset(member_var);
      } else { // members is empty
        log_debug("Adding " + dim + " to unknown list");
        c.unknown_dims.add(dim);
        calc_coordinates_next_known_dim(vars, c);
      }
    } else { // no known_dims left
      calc_coordinates_next_unknown_dim(vars, c);
    }

    end_function(vars);
  }

  int main(BashVars vars) {
    vars.return_value = 0;
    begin_function(vars);

    final Coordinates c = Coordinates.loadFrom(vars);
    int index = 0;
    for (String fieldName : c.coordinate_fields) {
      c.coordinate_dim_index.put(fieldName, index++);
    }

    int totalCoordRowsAdded = 0;
    if (c.coordinate_rows > 0) {
      log_verbose("Refining existing " + vars.get("coord_type") + " dim coordinates");
      for (c.row_index = 0; c.row_index < c.coordinate_rows; c.row_index++) {
        convert_coords_to_dims(vars, c, DimType.sdims);
        expand_dims(vars, c.known_dims);
        c.handle_unknown = HandleUnknownType.skip;
        calc_coordinates_next_known_dim(vars, c);
        log_debug("Finished coordinate row " + c.row_index+1 + " of " + c.coordinate_rows);
      }

    } else {
      log_verbose("Calculating $coord_type cell coordinates for dims: " + c.coordinate_fields);
      calc_coordinates_next_known_dim(vars, c);
    }

    end_function(vars);
    return vars.return_value;
  }

}



