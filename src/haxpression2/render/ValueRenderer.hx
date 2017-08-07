package haxpression2.render;

import haxpression2.Value;

class ValueRenderer {
  public static function render<N>(value : Value<N>, nToString : N -> String) : String {
    return switch value {
      case VNA: Values.NA_STR;
      case VNM: Values.NM_STR;
      case VInt(v) : Std.string(v);
      case VNum(v) : nToString(v);
      case VStr(v) : '"$v"';
      case VBool(v) : v ? "true" : "false";
    }
  }
}
