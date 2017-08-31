package haxpression2.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

import haxpression2.Value;

class ValueSchema {
  public static function schema<E, N>(nSchema : Schema<E, N>) : Schema<E, Value<N>> {
    return oneOf([
      constEnum("NA", VNA),
      constEnum("NM", VNM),
      alt(
        "int",
        int(),
        (value: Int) -> VInt(value),
        (value : Value<N>) -> switch value {
          case VInt(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "real",
        nSchema,
        (value: N) -> VReal(value),
        (value : Value<N>) -> switch value {
          case VReal(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "bool",
        bool(),
        (value: Bool) -> VBool(value),
        (value : Value<N>) -> switch value {
          case VBool(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "string",
        string(),
        (value: String) -> VStr(value),
        (value : Value<N>) -> switch value {
          case VStr(value) : Some(value);
          case _ : None;
        }
      ),
    ]);
  }
}
