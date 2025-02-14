import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Coordinates {
  public final List<String> coordinate_fields = new ArrayList<>();
  public final Map<String, Integer> coordinate_dim_index = new HashMap<>();
  public int coordinate_rows = 0;
  public HandleUnknownType handle_unknown = HandleUnknownType.error;
  public final List<String> known_dims = new ArrayList<>();
  public int row_index = 0;
  public int coordinate_fields_count = 0;
  public final List<String> coordinate_data = new ArrayList<>();
  public final List<String> coordinate_fields_plural = new ArrayList<>();

  public static Coordinates loadFrom(BashVars vars) {

  }
}
