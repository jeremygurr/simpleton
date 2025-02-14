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

  private List<String> expand_dim(BashVars vars, String value) {
    begin_function(vars);
    end_function(vars);
  }

  private List<String> expand_dim_members(BashVars vars, List<String> members) {
    begin_function(vars);
    final List<String> new_values = new ArrayList<>();
    for (String value : members) {
      List<String> values = expand_dim(vars, value);
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

        final List<String> new_values = expand_dim_members(vars, members);
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
        // TODO how to handle function failure?
        expand_dims(vars, c.known_dims);
        c.handle_unknown=HandleUnknownType.skip;
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



