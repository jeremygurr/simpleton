import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Coordinates {
  public final List<String> coordinate_fields;
  public final Map<String, Integer> coordinate_dim_index;
  public int coordinate_rows;
  public HandleUnknownType handle_unknown;
  public final List<String> known_dims;
  public final List<String> unknown_dims;
  public final List<String> resolved_dims;
  public int row_index;
  public int coordinate_fields_count;
  public final List<String> coordinate_data;
  public final List<String> coordinate_fields_plural;

  private Coordinates() {
    coordinate_fields = new ArrayList<>();
    coordinate_dim_index = new HashMap<>();
    coordinate_rows = 0;
    handle_unknown = HandleUnknownType.error;
    known_dims = new ArrayList<>();
    unknown_dims = new ArrayList<>();
    resolved_dims = new ArrayList<>();
    row_index = 0;
    coordinate_fields_count = 0;
    coordinate_data = new ArrayList<>();
    coordinate_fields_plural = new ArrayList<>();
  }

  private Coordinates(List<String> coordinate_fields, Map<String, Integer> coordinate_dim_index, int coordinate_rows, HandleUnknownType handle_unknown, List<String> known_dims, List<String> unknown_dims, List<String> resolved_dims, int row_index, int coordinate_fields_count, List<String> coordinate_data, List<String> coordinate_fields_plural) {
    this.coordinate_fields = coordinate_fields;
    this.coordinate_dim_index = coordinate_dim_index;
    this.coordinate_rows = coordinate_rows;
    this.handle_unknown = handle_unknown;
    this.known_dims = known_dims;
    this.unknown_dims = unknown_dims;
    this.resolved_dims = resolved_dims;
    this.row_index = row_index;
    this.coordinate_fields_count = coordinate_fields_count;
    this.coordinate_data = coordinate_data;
    this.coordinate_fields_plural = coordinate_fields_plural;
  }

  public static Coordinates loadFrom(BashVars vars) {

  }

  public static Coordinates make() {
    return new Coordinates();
  }

  public static Coordinates make(Coordinates c) {
    return new Coordinates(
        new ArrayList<>(c.coordinate_fields),
        c.coordinate_dim_index,
        c.coordinate_rows,
        c.handle_unknown,
        new ArrayList<>(c.known_dims),
        new ArrayList<>(c.unknown_dims),
        new ArrayList<>(c.resolved_dims),
        c.row_index,
        c.coordinate_fields_count,
        new ArrayList<>(c.coordinate_data),
        new ArrayList<>(c.coordinate_fields_plural)
    );
  }

}
