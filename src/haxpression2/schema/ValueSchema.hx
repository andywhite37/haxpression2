package haxpression2.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

import haxpression2.Value;

class ValueSchema {
  public static function schema<E, N>(nSchema : Schema<E, N>) : Schema<E, Value<N>> {
    return oneOf([
      constEnum("VNA", VNA),
      constEnum("VNM", VNM),
      alt(
        "VInt",
        int(),
        (value: Int) -> VInt(value),
        (value : Value<N>) -> switch value {
          case VInt(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "VReal",
        nSchema,
        (value: N) -> VReal(value),
        (value : Value<N>) -> switch value {
          case VReal(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "VBool",
        bool(),
        (value: Bool) -> VBool(value),
        (value : Value<N>) -> switch value {
          case VBool(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "VStr",
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
